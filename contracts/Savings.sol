//SPDX-License-Idenditifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// user connects wallet
// user deploys savings contract with the savings name and the chosen stable token
// when deployed, smart contract automatically creates a general savings
// user can deposit into the savings contract
// user can then create a new savings box
// user can deposit into the newly created savings box and set a  timer
// user can see the total savings

error Savings__NotEqualEtherForFee();
error Savings__UnlockTimeNotReached();
error Savings__TransactionFailed();

contract Savings is Ownable {
    // Type Declarations
    using PriceConverter for uint256;
    using SafeERC20 for IERC20;

    struct SavingPlan {
        string savingPlanName;
        uint256 total;
        uint256 target;
        uint256 unlockTime;
    }

    string private s_savingsName;
    address private immutable i_owner;
    address private immutable i_stableTokenAddress;
    address private s_contractAddr;
    mapping(uint256 => SavingPlan) private s_idToSavingPlan;
    uint256 private s_savingPlansCounter;
    uint256 public constant DEPLOY_FEE = 1 * 10 ** 18;
    address private constant BLOCKXAVE_ADDRESS = 0x6fb462259dEE0956FfAE3a87C8481885c2db34bB;

    event FundsDesposited(address indexed saver, uint256 amount);
    event FundsWithdrawn(address indexed saver, uint256 amount);

    constructor(
        string memory _savingsName,
        address _stableTokenAddress // address priceFeed
    ) {
        // if (msg.value.getConversionRate(AggregatorV3Interface(priceFeed)) != DEPLOY_FEE) {
        //     revert Savings__NotEqualEtherForFee();
        // }

        // (bool callSuccess, ) = BLOCKXAVE_ADDRESS.call{value: msg.value}("");
        // if (!callSuccess) revert Savings__TransactionFailed();

        bool callSuccess = IERC20(_stableTokenAddress).transferFrom(
            msg.sender,
            BLOCKXAVE_ADDRESS,
            DEPLOY_FEE
        );
        if (!callSuccess) {
            revert Savings__TransactionFailed();
        }

        s_savingsName = _savingsName;

        SavingPlan memory generalSavings = SavingPlan("General savings", 0, 0, block.timestamp);
        s_idToSavingPlan[s_savingPlansCounter] = generalSavings;

        s_savingPlansCounter += 1;

        i_owner = msg.sender;
        i_stableTokenAddress = _stableTokenAddress;
    }

    function createSavingPlan(
        string memory _savingsPlanName,
        uint256 _amount,
        uint256 _target,
        uint256 _unlockTime
    ) external onlyOwner returns (uint256) {
        SavingPlan memory savingPlan = SavingPlan(_savingsPlanName, _amount, _target, _unlockTime);
        s_idToSavingPlan[s_savingPlansCounter] = savingPlan;
        s_savingPlansCounter += 1;

        return s_savingPlansCounter - 1;
    }

    //  deposit
    function deposit(uint256 id, address _contractAddr, uint256 _amount) external onlyOwner {
        s_contractAddr = _contractAddr;

        //    transfer the savings money from the saver to the contract
        IERC20(i_stableTokenAddress).safeTransferFrom(i_owner, _contractAddr, _amount);

        emit FundsDesposited(i_owner, _amount);

        SavingPlan memory savingPlan = s_idToSavingPlan[id];

        savingPlan.total += _amount;
    }

    function withdraw(uint id) external onlyOwner {
        SavingPlan memory savingPlan = s_idToSavingPlan[id];

        bool timePassed = block.timestamp >= savingPlan.unlockTime;
        if (!timePassed) {
            revert Savings__UnlockTimeNotReached();
        }

        //    transfer the saved money from the contract to the saver
        IERC20(i_stableTokenAddress).safeTransferFrom(s_contractAddr, i_owner, savingPlan.total);

        emit FundsWithdrawn(i_owner, savingPlan.total);

        savingPlan.total = 0;
    }

    function getSavingPlanName(uint256 id) public view returns (string memory) {
        SavingPlan memory savingPlan = s_idToSavingPlan[id];
        return savingPlan.savingPlanName;
    }

    function getContractBalance() public view returns (uint256) {
        uint256 contractBalance = IERC20(i_stableTokenAddress).balanceOf(s_contractAddr);
        return contractBalance;
    }

    function getUnlockTimeForSavingPlan(uint256 id) public view returns (uint256) {
        SavingPlan memory savingPlan = s_idToSavingPlan[id];
        return savingPlan.unlockTime;
    }

    function getTotalAmountInSavingPlan(uint256 id) public view returns (uint256) {
        SavingPlan memory savingPlan = s_idToSavingPlan[id];
        return savingPlan.total;
    }
}
