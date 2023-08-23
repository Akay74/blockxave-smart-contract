//SPDX-License-Idenditifier: MIT
pragma solidity ^0.8.4;

//Connect user wallet to dApp
//Allow user create and customise saving plan
//Allow user deploy a savings contract
//Allow user approve the contract to take and store funds for a particular amount of time
//Display user funds when they connect to the dApp after funding
//Allow user to withdraw funds from immediate savings
//Deposit funds back to user when time for saving elapses and also send incentive token
//Allow user to stake stable tokens for monthly or yearly time period
//Deposit funds to user address after staking time elapses

contract Savings {
  string private immutable i_savingsName;
  address public s_owner;

  constructor(string memory _savingsName) {
    i_savingsName = _savingsName;
    s_owner = msg.sender;
  }

//  deposit
  function deposit(address _contractAddr, uint256 _amount) external{
//      if the owner of the contract has that amount in dai
//    approve the contract to save the chosen _amount
//    transfer chosen amount from the owner to the contract
//    calculate interest to be gained of the blockxafe token

  }

  function withdraw() internal{
// use chainlink keepers to track the amount of time needed for withdrawal
  }

  function getSavingsName() public view returns (string memory) {
    return i_savingsName;
  }
}
