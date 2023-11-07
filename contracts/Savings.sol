//SPDX-License-Idenditifier: MIT;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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

    event FundsDesposited(address indexed saver, uint256 amount);
    event FundsWithdrawn(address indexed saver, uint256 amount);

    constructor(string memory _savingsName, address _stableTokenAddress) {
        s_savingsName = _savingsName;
        i_owner = msg.sender;
        s_stableToken = IERC20(_stableTokenAddress);
    }

    function createSavingPlan(
        string memory _savingsPlanName,
        uint256 _amount,
        uint256 _target,
        uint256 _unlockTime
    ) external onlyOwner returns (uint256) {
        s_stableToken.transferFrom(i_owner, address(this), _amount);

        uint256 unlockTime = block.timestamp + (_unlockTime * 1 days);

        SavingPlan memory savingPlan = SavingPlan(_savingsPlanName, _amount, _target, unlockTime);
        s_idToSavingPlan[s_savingPlansCounter] = savingPlan;
        s_savingPlansCounter += 1;

        if (s_savingPlansCounter == 0) {
            return s_savingPlansCounter;
        } else {
            return s_savingPlansCounter - 1;
        }
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

        /**
         *
         * if the total amount saved = saving target
         * if the saving plan unlock time meets a certain time threshold, then transfer blockxave token according to the time threshold
         */

        savingPlan.total = 0;
        savingPlan.target = 0;
        savingPlan.unlockTime = 0;

        emit FundsWithdrawn(i_owner, savingPlan.total);
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
