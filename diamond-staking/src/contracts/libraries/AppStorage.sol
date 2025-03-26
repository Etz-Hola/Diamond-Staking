// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "./LibDiamond.sol";

struct StakingInfo {
    uint256 amount;
    uint256 lastUpdateTime;
    uint256 rewardDebt;
}

struct NFTStakingInfo {
    uint256[] stakedTokenIds;
    uint256 lastUpdateTime;
    uint256 rewardDebt;
}

struct ERC1155StakingInfo {
    mapping(uint256 => uint256) stakedAmounts;
    uint256 lastUpdateTime;
    uint256 rewardDebt;
}

struct AppStorage {
    // Token addresses
    address diamondToken;
    
    // Staking mappings
    mapping(address => mapping(address => StakingInfo)) erc20Stakes;
    mapping(address => mapping(address => NFTStakingInfo)) erc721Stakes;
    mapping(address => mapping(address => ERC1155StakingInfo)) erc1155Stakes;
    
    // Reward parameters
    uint256 rewardRate; // Rewards per second per token
    uint256 decayRate; // Rate at which rewards decrease over time
    uint256 lastUpdateTime;
    
    // Total staked amounts
    mapping(address => uint256) totalStakedERC20;
    mapping(address => uint256) totalStakedERC721;
    mapping(address => uint256) totalStakedERC1155;
    
    // Pausable
    bool paused;
    
    // Access control
    mapping(address => bool) isAdmin;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
} 