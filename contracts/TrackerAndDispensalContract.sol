//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

//  * create a tracker contract
//  * it should track how much is deposited each time a deposit is made, also the target and unlock time
//  * the tracker contract should also have blockxave tokens so it can incetivize users that reach their target and this incentivizatiion depends on the length of the unlock time.

error TrackerAndDispensal_User_Is_Not_Eligible();

contract TrackerAndDispensal {
    // states
    /**
     * @mapping address to savingPlanInfo
     */

    struct SavingPlanInfo {
        string savingPlanName;
        uint256 total;
        uint256 target;
        uint256 unlockTime;
    }

    IERC20 private s_stableToken;

    mapping(address => mapping(uint => SavingPlanInfo)) private addressToSavingPlanInfo;

    constructor(address _blockXaveTokeAddress) {
        s_stableToken = IERC20(_blockXaveTokeAddress);
    }

    // functions
    /**
     *   updateUserInfoForEveryDeposit
     *  payUserThatMeets the criteria
     */

    function updateUserInfoForEveryDeposit(
        SavingPlanInfo memory info,
        uint256 savingPlanId
    ) public {
        addressToSavingPlanInfo[msg.sender][savingPlanId] = info;
    }

    function checkIfUserMeetsCriteria(
        address owner,
        uint256 savingPlanId
    ) internal view returns (bool) {
        SavingPlanInfo memory ownerSavingPlanInfo = addressToSavingPlanInfo[owner][savingPlanId];

        // check first if users' saving plan is created or current
        if (ownerSavingPlanInfo.total == 0) {
            return false;
        }

        // check if the user meets his target
        if (ownerSavingPlanInfo.total >= ownerSavingPlanInfo.target) {
            return true;
        }
        return false;
    }

    function payUser(uint256 savingPlanId) public {
        // check if user is eligible for the blockxave token bonus
        bool userPassed = checkIfUserMeetsCriteria(msg.sender, savingPlanId);

        if (!userPassed) {
            revert TrackerAndDispensal_User_Is_Not_Eligible();
        }

        // after you have payed user
        addressToSavingPlanInfo[msg.sender][savingPlanId].total = 0;
    }
}
