// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibRewards} from "../libraries/LibRewards.sol";

contract ERC20StakingFacet {
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);

    function stakeERC20(address token, uint256 amount) external {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        require(amount > 0, "Amount must be greater than 0");
        
        // Update rewards before changing balance
        LibRewards.updateRewards(msg.sender, token);
        
        // Transfer tokens from user
        require(IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Update staking balances
        s.erc20Stakes[msg.sender][token] += amount;
        s.erc20Pools[token].totalStaked += amount;
        
        emit Staked(msg.sender, token, amount);
    }

    function unstakeERC20(address token, uint256 amount) external {
        // ... implementation
    }
}