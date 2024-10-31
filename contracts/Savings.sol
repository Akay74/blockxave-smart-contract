// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Savings Contract
 * @author Original: Ejim Favour, Refactored by Akay
 * @notice This contract allows users to create and manage various savings plans using stablecoins
 * @dev Implements saving plans with both fixed and flexible withdrawal options
 */

error SavingsUnlockTimeNotReached();
error SavingsDepositFailed();
error SavingsTransferFailed();
error SavingsInvalidAmount();
error SavingsInvalidPlanId();
error SavingsInvalidUnlockTime();

contract Savings is Ownable, ReentrancyGuard {
    // Type Declarations
    struct SavingPlan {
        string savingPlanName;
        bool fixedPlan;
        uint256 total;
        uint256 target;
        uint256 unlockTime;
    }

    IERC20 private immutable s_stableToken;
    string private immutable s_savingsName;
    
    mapping(uint256 => SavingPlan) private s_idToSavingPlan;
    uint256 private s_savingPlansCounter;

    event FundsDeposited(
        address indexed saver, 
        uint256 indexed planId, 
        uint256 amount, 
        uint256 newTotal
    );
    event FundsWithdrawn(
        address indexed saver, 
        uint256 indexed planId, 
        uint256 amount
    );
    event SavingPlanCreated(
        uint256 indexed planId, 
        string planName, 
        bool fixedPlan, 
        uint256 target
    );

    /**
     * @notice Initialize the savings contract with a name and stablecoin address
     * @param _savingsName Name of the savings contract
     * @param _stableTokenAddress Address of the stablecoin to be used
     */
    constructor(
        string memory _savingsName, 
        address _stableTokenAddress
    ) Ownable(msg.sender) {
        if (_stableTokenAddress == address(0)) revert SavingsInvalidAmount();
        
        s_savingsName = _savingsName;
        s_stableToken = IERC20(_stableTokenAddress);
    }

    /**
     * @notice Creates a new saving plan
     * @param _savingsPlanName Name of the savings plan
     * @param _fixedPlan Whether the plan has a fixed lock period
     * @param _amount Initial deposit amount
     * @param _target Target savings amount
     * @param _unlockTime Lock period in days
     * @return planId The ID of the created savings plan
     */
    function createSavingPlan(
        string memory _savingsPlanName,
        bool _fixedPlan,
        uint256 _amount,
        uint256 _target,
        uint256 _unlockTime
    ) external onlyOwner nonReentrant returns (uint256 planId) {
        if (_amount == 0) revert SavingsInvalidAmount();
        if (_unlockTime == 0) revert SavingsInvalidUnlockTime();

        bool success = s_stableToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert SavingsDepositFailed();

        uint256 unlockTime = block.timestamp + (_unlockTime * 1 days);
        
        planId = s_savingPlansCounter++;
        s_idToSavingPlan[planId] = SavingPlan(
            _savingsPlanName,
            _fixedPlan,
            _amount,
            _target,
            unlockTime
        );

        emit SavingPlanCreated(planId, _savingsPlanName, _fixedPlan, _target);
        emit FundsDeposited(msg.sender, planId, _amount, _amount);
    }

    /**
     * @notice Deposits funds into an existing saving plan
     * @param id The savings plan ID
     * @param _amount Amount to deposit
     */
    function deposit(
        uint256 id, 
        uint256 _amount
    ) external onlyOwner nonReentrant {
        if (_amount == 0) revert SavingsInvalidAmount();
        if (id >= s_savingPlansCounter) revert SavingsInvalidPlanId();

        bool success = s_stableToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert SavingsDepositFailed();

        SavingPlan storage savingPlan = s_idToSavingPlan[id];
        uint256 newTotal = savingPlan.total + _amount;
        savingPlan.total = newTotal;

        emit FundsDeposited(msg.sender, id, _amount, newTotal);
    }

    /**
     * @notice Withdraws funds from a saving plan
     * @param _id The savings plan ID
     */
    function withdrawFromSavingPlan(
        uint256 _id
    ) external onlyOwner nonReentrant {
        if (_id >= s_savingPlansCounter) revert SavingsInvalidPlanId();

        SavingPlan storage savingPlan = s_idToSavingPlan[_id];
        uint256 withdrawAmount = savingPlan.total;

        if (block.timestamp < savingPlan.unlockTime && savingPlan.fixedPlan) {
            revert SavingsUnlockTimeNotReached();
        }

        // Update state before external call to prevent reentrancy
        savingPlan.total = 0;
        savingPlan.target = 0;
        savingPlan.unlockTime = 0;

        bool success = s_stableToken.transfer(msg.sender, withdrawAmount);
        if (!success) revert SavingsTransferFailed();

        emit FundsWithdrawn(msg.sender, _id, withdrawAmount);
    }

    /**
     * @notice Gets the name of a specific saving plan
     * @param id The savings plan ID
     * @return The name of the saving plan
     */
    function getSavingPlanName(
        uint256 id
    ) external view returns (string memory) {
        if (id >= s_savingPlansCounter) revert SavingsInvalidPlanId();
        return s_idToSavingPlan[id].savingPlanName;
    }

    /**
     * @notice Gets the total balance of the contract
     * @return The contract's total balance
     */
    function getContractBalance() external view returns (uint256) {
        return s_stableToken.balanceOf(address(this));
    }

    /**
     * @notice Gets the total number of saving plans
     * @return The number of saving plans
     */
    function getSavingPlanCount() external view returns (uint256) {
        return s_savingPlansCounter;
    }

    /**
     * @notice Gets the details of a specific saving plan
     * @param id The savings plan ID
     * @return The saving plan details
     */
    function getSavingPlan(
        uint256 id
    ) external view returns (SavingPlan memory) {
        if (id >= s_savingPlansCounter) revert SavingsInvalidPlanId();
        return s_idToSavingPlan[id];
    }

    /**
     * @notice Gets the balance of a specific saving plan
     * @param _id The savings plan ID
     * @return The balance of the saving plan
     */
    function getSavingPlanBalance(
        uint256 _id
    ) external view returns (uint256) {
        if (_id >= s_savingPlansCounter) revert SavingsInvalidPlanId();
        return s_idToSavingPlan[_id].total;
    }
}