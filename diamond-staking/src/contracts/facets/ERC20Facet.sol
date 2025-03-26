// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";

contract ERC20Facet is IERC20 {
    function name() external view override returns (string memory) {
        return LibAppStorage.diamondStorage().name;
    }

    function symbol() external view override returns (string memory) {
        return LibAppStorage.diamondStorage().symbol;
    }

    function decimals() external view override returns (uint8) {
        return LibAppStorage.diamondStorage().decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return LibAppStorage.diamondStorage().totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return LibAppStorage.diamondStorage().balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.balances[msg.sender] >= amount, "ERC20: insufficient balance");
        s.balances[msg.sender] -= amount;
        s.balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // ... other ERC20 functions
}