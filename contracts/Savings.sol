//SPDX-License-Idenditifier: MIT;
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// user actions
// deploy savings contract
// create a saving plan
// deposit into the saving plan
// withdraw from the saving plan

error Savings__UnlockTimeNotReached();
error Savings__DepositFailed();
error Savings__TransferFailed();

/*
 * @contract Savings Contract
 * @author Ejim Favour
 */

contract Savings is Ownable {
    // Type Declarations
    struct SavingPlan {
        string savingPlanName;
        bool fixedPlan;
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

    /*
     * @param _savingsName and _stableTokenAddress
     */
    constructor(string memory _savingsName, address _stableTokenAddress) {
        s_savingsName = _savingsName;
        i_owner = msg.sender;
        s_stableToken = IERC20(_stableTokenAddress);
    }

    // Fallback function must be declared as external.
    fallback() external payable {
        getContractBalance();
    }

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {
        getContractBalance();
    }

    /*
     * @param _savingsPlanName, _amount. _target, _unlockTime
     * @func it is a function for creating a saving plan
     */
    function createSavingPlan(
        string memory _savingsPlanName,
        bool _fixedPlan,
        uint256 _amount,
        uint256 _target,
        uint256 _unlockTime
    ) external onlyOwner {
        bool callSuccess = s_stableToken.transferFrom(i_owner, address(this), _amount);

        if (!callSuccess) revert Savings__DepositFailed();

        uint256 unlockTime = block.timestamp + (_unlockTime * 1 days);

        SavingPlan memory savingPlan = SavingPlan(
            _savingsPlanName,
            _fixedPlan,
            _amount,
            _target,
            unlockTime
        );
        s_idToSavingPlan[s_savingPlansCounter] = savingPlan;
        s_savingPlansCounter += 1;
    }

    /*
     * @param id and _amount
     * @func it is a function for depositing into a saving plan
     */
    //  deposit
    function deposit(uint256 id, uint256 _amount) external onlyOwner {
        //    transfer the savings money from the saver to the contract
        bool callSuccess = s_stableToken.transferFrom(i_owner, address(this), _amount);

        if (!callSuccess) revert Savings__DepositFailed();

        emit FundsDesposited(i_owner, _amount);

        SavingPlan storage savingPlan = s_idToSavingPlan[id];

        savingPlan.total += _amount;
    }

    /*
     * @param _id
     * @func it is a function for withdrawing from a saving plan
     */
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
