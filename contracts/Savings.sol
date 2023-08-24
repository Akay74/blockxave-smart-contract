//SPDX-License-Idenditifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//Connect user wallet to dApp
//Allow user create and customise saving plan
//Allow user deploy a savings contract
//Allow user approve the contract to take and store funds for a particular amount of time
//Display user funds when they connect to the dApp after funding
//Allow user to withdraw funds from immediate savings
//Deposit funds back to user when time for saving elapses and also send incentive token
//Allow user to stake stable tokens for monthly or yearly time period
//Deposit funds to user address after staking time elapses


// deploy contract
// desposit funds:
//- approve transfer of funds from saver to the contract --- outside the contract
//- transfer funds from saver to contract
//- approve the transfer of funds from the contract to the saver --- outside the contract
// withdraw funds:
//- chainlink keepers check for unlock time to elapse
//- when time elapses, it calls the withdraw function which transfer saved funds from contract to saver
//- It also mints the blockxafe token to the saver


error Savings__UnlockTimeNotReached();

contract Savings is Ownable {
  using SafeERC20 for IERC20;


  string private  s_savingsName;
  address private immutable i_owner;
  address private immutable i_stableTokenAddress;
  address private s_contractAddr;
  uint256 private immutable i_unlockTime;


  event FundsDesposited(address indexed saver, uint amount);
  event FundsWithdrawn(address indexed saver, uint amount);


  constructor(string memory _savingsName, address _stableTokenAddress, uint256 _unlockTime) {
    s_savingsName = _savingsName;
    i_owner = msg.sender;
    i_stableTokenAddress = _stableTokenAddress;
    i_unlockTime = _unlockTime;
  }

//  deposit
  function deposit(address _contractAddr, uint256 _amount) external onlyOwner{

    s_contractAddr = _contractAddr;

//    transfer the savings money from the saver to the contract
    IERC20(i_stableTokenAddress).safeTransferFrom(i_owner,_contractAddr,_amount);

    emit FundsDesposited(i_owner, _amount);
  }

  function withdraw() external onlyOwner{
    bool timePassed = block.timestamp >= i_unlockTime;
    if(!timePassed){
      revert Savings__UnlockTimeNotReached();
    }

//    get the contract balance of the stable token
    uint256 contractBalance = IERC20(i_stableTokenAddress).balanceOf(s_contractAddr);
//    transfer the saved money from the contract to the saver
    IERC20(i_stableTokenAddress).safeTransferFrom(s_contractAddr,i_owner,contractBalance);

    emit FundsWithdrawn(i_owner, contractBalance);
  }


  function getSavingsName() public view returns (string memory) {
    return s_savingsName;
  }

  function getContractBalance() public view returns(uint){
    uint256 contractBalance = IERC20(i_stableTokenAddress).balanceOf(s_contractAddr);
    return contractBalance;
  }

  function getUnlockTime() public view returns(uint){
    return i_unlockTime;
  }
}
