// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AppStorage} from "../libraries/AppStorage.sol";

contract ERC20Facet {
    AppStorage.Layout internal l;

    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function stakeERC20(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        l.stakedAmount[msg.sender][token] += amount;
        l.stakingTimestamp[msg.sender][token] = block.timestamp;
        l.lastRewardClaim[msg.sender][token] = block.timestamp;
        l.totalStaked[token] += amount;

        emit Staked(msg.sender, token, amount);
    }

    function unstakeERC20(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(l.stakedAmount[msg.sender][token] >= amount, "Insufficient staked amount");
        require(block.timestamp >= l.stakingTimestamp[msg.sender][token] + l.minStakeDuration, "Staking period not met");

        // Calculate and claim rewards before unstaking
        uint256 rewards = calculateRewards(msg.sender, token);
        if (rewards > 0) {
            _mintRewards(msg.sender, rewards);
        }

        l.stakedAmount[msg.sender][token] -= amount;
        l.totalStaked[token] -= amount;
        l.lastRewardClaim[msg.sender][token] = block.timestamp;

        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");

        emit Unstaked(msg.sender, token, amount);
    }

    function claimRewards(address token) external {
        uint256 rewards = calculateRewards(msg.sender, token);
        require(rewards > 0, "No rewards to claim");

        _mintRewards(msg.sender, rewards);
        l.lastRewardClaim[msg.sender][token] = block.timestamp;

        emit RewardsClaimed(msg.sender, rewards);
    }

    function calculateRewards(address user, address token) public view returns (uint256) {
        uint256 stakedAmount = l.stakedAmount[user][token];
        if (stakedAmount == 0) return 0;

        uint256 timeStaked = block.timestamp - l.lastRewardClaim[user][token];
        uint256 baseReward = (stakedAmount * l.rewardRate * timeStaked) / (365 days * 10000);
        
        // Apply decay rate based on time staked
        uint256 totalTimeStaked = block.timestamp - l.stakingTimestamp[user][token];
        uint256 decayFactor = 10000 - (totalTimeStaked * l.decayRate / (365 days * 10000));
        if (decayFactor < 5000) decayFactor = 5000; // Minimum 50% of base reward

        return (baseReward * decayFactor) / 10000;
    }

    function _mintRewards(address to, uint256 amount) internal {
        // Since the Diamond contract itself is the reward token, we just need to update balances
        // This is a simplified version - in a real implementation, you'd want to use a proper ERC20 implementation
        l.stakedAmount[to][address(this)] += amount;
        l.totalStaked[address(this)] += amount;
    }

    function getStakedAmount(address user, address token) external view returns (uint256) {
        return l.stakedAmount[user][token];
    }

    function getTotalStaked(address token) external view returns (uint256) {
        return l.totalStaked[token];
    }

    function getStakingTimestamp(address user, address token) external view returns (uint256) {
        return l.stakingTimestamp[user][token];
    }

    function getLastRewardClaim(address user, address token) external view returns (uint256) {
        return l.lastRewardClaim[user][token];
    }
}