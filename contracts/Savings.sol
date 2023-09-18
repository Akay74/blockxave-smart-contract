//SPDX-License-Idenditifier: MIT;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// user connects wallet
// user deploys savings contract with the savings name and the chosen stable token
// when deployed, smart contract automatically creates a general savings
// user can deposit into the savings contract
// user can then create a new savings box
// user can deposit into the newly created savings box and set a  timer
// user can see the total savings

error Savings__UnlockTimeNotReached();
error Savings__DepositFailed();
error Savings__TransferFailed();

contract Savings is Ownable {
    // Type Declarations
    using SafeERC20 for IERC20;

    struct SavingPlan {
        string savingPlanName;
        uint256 total;
        uint256 target;
        uint256 unlockTime;
    }

    IERC20 private s_stableToken;

    string private s_savingsName;
    address private immutable i_owner;
    mapping(uint256 => SavingPlan) private s_idToSavingPlan;
    uint256 private s_savingPlansCounter;
    uint256 public constant DEPLOY_FEE = 1 * 10 ** 18;
    address private constant BLOCKXAVE_ADDRESS = 0x6fb462259dEE0956FfAE3a87C8481885c2db34bB;

    event FundsDesposited(address indexed saver, uint256 amount);
    event FundsWithdrawn(address indexed saver, uint256 amount);

    constructor(string memory _savingsName, address _stableTokenAddress) {
        s_savingsName = _savingsName;

        SavingPlan memory generalSavings = SavingPlan("General savings", 0, 0, block.timestamp);
        s_idToSavingPlan[s_savingPlansCounter] = generalSavings;

        s_savingPlansCounter += 1;

        i_owner = msg.sender;
        s_stableToken = IERC20(_stableTokenAddress);
    }

    function createSavingPlan(
        string memory _savingsPlanName,
        uint256 _amount,
        uint256 _target,
        uint256 _unlockTime
    ) external onlyOwner {
        s_stableToken.transferFrom(i_owner, address(this), _amount);

        uint256 unlockTime = block.timestamp + (_unlockTime * 1 days);

        SavingPlan memory savingPlan = SavingPlan(_savingsPlanName, _amount, _target, unlockTime);
        s_idToSavingPlan[s_savingPlansCounter] = savingPlan;
        s_savingPlansCounter += 1;
    }

    //  deposit
    function deposit(uint256 id, uint256 _amount) external onlyOwner {
        //    transfer the savings money from the saver to the contract
        bool callSucess = s_stableToken.transferFrom(i_owner, address(this), _amount);

        if (!callSucess) revert Savings__DepositFailed();

        emit FundsDesposited(i_owner, _amount);

        SavingPlan storage savingPlan = s_idToSavingPlan[id];

        savingPlan.total += _amount;
    }

    function withdrawFromSavingPlan(uint256 _id) external onlyOwner {
        SavingPlan storage savingPlan = s_idToSavingPlan[_id];

        if (block.timestamp < savingPlan.unlockTime) {
            revert Savings__UnlockTimeNotReached();
        }

        //    transfer the saved money from the contract to the saver
        bool callSuccess = s_stableToken.transfer(i_owner, savingPlan.total);
        if (!callSuccess) revert Savings__TransferFailed();

        savingPlan.total = 0;
        savingPlan.target = 0;
        savingPlan.unlockTime = 0;

        // emit FundsWithdrawn(i_owner, savingPlan.total);
    }

    function withdrawFromGeneralSavings(uint256 _amount) external onlyOwner {
        SavingPlan storage savingPlan = s_idToSavingPlan[0];

        //    transfer the saved money from the contract to the saver
        bool callSuccess = s_stableToken.transfer(i_owner, _amount);
        if (!callSuccess) revert Savings__TransferFailed();

        savingPlan.total -= _amount;
        savingPlan.target = 0;
        savingPlan.unlockTime = 0;
    }

    function getSavingPlanName(uint256 id) public view returns (string memory) {
        SavingPlan memory savingPlan = s_idToSavingPlan[id];
        return savingPlan.savingPlanName;
    }

    function getContractBalance() public view returns (uint256) {
        uint256 contractBalance = s_stableToken.balanceOf(address(this));
        return contractBalance;
    }

    function getSavingPlanCount() public view returns (uint256) {
        return s_savingPlansCounter;
    }

    function getSavingPlan(uint256 id) public view returns (SavingPlan memory) {
        return s_idToSavingPlan[id];
    }

    function getSavingPlanBalance(uint256 _id) public view returns (uint256) {
        return s_idToSavingPlan[_id].total;
    }
}
