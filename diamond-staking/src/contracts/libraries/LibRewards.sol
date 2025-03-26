// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage} from "./LibAppStorage.sol";

library LibRewards {
    function updateRewards(address user, address token) internal {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 reward = calculatePendingRewards(user, token);
        s.erc20Rewards[user][token] = reward;
        s.lastClaimTime[user] = block.timestamp;
    }

    function calculatePendingRewards(address user, address token) internal view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 stakedAmount = s.erc20Stakes[user][token];
        if (stakedAmount == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - s.erc20Pools[token].lastUpdateTime;
        uint256 rewardRate = s.erc20Pools[token].rewardRate;
        
        return stakedAmount * rewardRate * timeElapsed / 1e18;
    }
}