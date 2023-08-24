// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockXafeToken is ERC20, Ownable {
    constructor(uint256 _initialSupply) ERC20("Blockxafe-Token", "BXT"){
        _mint(msg.sender, _initialSupply);
    }

    function incentivizeSavers(address saver, uint256 amount) external onlyOwner {
        _mint(saver, amount);
    }
}
