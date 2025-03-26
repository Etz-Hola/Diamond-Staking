// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {AppStorage} from "../libraries/AppStorage.sol";

contract ERC1155Facet {
    AppStorage.Layout internal l;

    event ERC1155Staked(address indexed user, address indexed token, uint256 tokenId, uint256 amount);
    event ERC1155Unstaked(address indexed user, address indexed token, uint256 tokenId, uint256 amount);
    event ERC1155RewardsClaimed(address indexed user, uint256 amount);

    function stakeERC1155(address token, uint256 tokenId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC1155(token).isApprovedForAll(msg.sender, address(this)), "Contract not approved");

        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        l.stakedERC1155[msg.sender][tokenId] += amount;
        l.stakingTimestamp[msg.sender][token] = block.timestamp;
        l.lastRewardClaim[msg.sender][token] = block.timestamp;
        l.totalStaked[token] += amount;

        emit ERC1155Staked(msg.sender, token, tokenId, amount);
    }

    function unstakeERC1155(address token, uint256 tokenId, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(l.stakedERC1155[msg.sender][tokenId] >= amount, "Insufficient staked amount");
        require(block.timestamp >= l.stakingTimestamp[msg.sender][token] + l.minStakeDuration, "Staking period not met");

        // Calculate and claim rewards before unstaking
        uint256 rewards = calculateERC1155Rewards(msg.sender, token);
        if (rewards > 0) {
            _mintRewards(msg.sender, rewards);
        }

        l.stakedERC1155[msg.sender][tokenId] -= amount;
        l.totalStaked[token] -= amount;
        l.lastRewardClaim[msg.sender][token] = block.timestamp;

        IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        emit ERC1155Unstaked(msg.sender, token, tokenId, amount);
    }

    function claimERC1155Rewards(address token) external {
        uint256 rewards = calculateERC1155Rewards(msg.sender, token);
        require(rewards > 0, "No rewards to claim");

        _mintRewards(msg.sender, rewards);
        l.lastRewardClaim[msg.sender][token] = block.timestamp;

        emit ERC1155RewardsClaimed(msg.sender, rewards);
    }

    function calculateERC1155Rewards(address user, address token) public view returns (uint256) {
        uint256 totalStaked = getTotalERC1155Staked(user, token);
        if (totalStaked == 0) return 0;

        uint256 timeStaked = block.timestamp - l.lastRewardClaim[user][token];
        uint256 baseReward = (totalStaked * l.rewardRate * timeStaked) / (365 days * 10000);
        
        // Apply decay rate based on time staked
        uint256 totalTimeStaked = block.timestamp - l.stakingTimestamp[user][token];
        uint256 decayFactor = 10000 - (totalTimeStaked * l.decayRate / (365 days * 10000));
        if (decayFactor < 5000) decayFactor = 5000; // Minimum 50% of base reward

        return (baseReward * decayFactor) / 10000;
    }

    function getTotalERC1155Staked(address user, address token) public view returns (uint256) {
        uint256 total = 0;
        // Note: This is a simplified version. In a real implementation, you'd want to track staked tokens more efficiently
        for (uint256 i = 0; i < 10000; i++) { // Assuming max 10000 token IDs per contract
            total += l.stakedERC1155[user][i];
        }
        return total;
    }

    function getERC1155StakedAmount(address user, uint256 tokenId) external view returns (uint256) {
        return l.stakedERC1155[user][tokenId];
    }

    function _mintRewards(address to, uint256 amount) internal {
        l.stakedAmount[to][address(this)] += amount;
        l.totalStaked[address(this)] += amount;
    }
} 