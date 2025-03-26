// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibAppStorage {
    bytes32 constant APP_STORAGE_POSITION = keccak256("diamond.staking.app");

    struct StakingPool {
        uint256 totalStaked;
        uint256 rewardRate;
        uint256 decayRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    struct AppStorage {
        // ERC20 Token
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        
        // Staking
        mapping(address => StakingPool) erc20Pools;
        mapping(address => mapping(address => uint256)) erc20Stakes;
        mapping(address => mapping(address => uint256)) erc20Rewards;
        
        // ERC721
        mapping(address => uint256) erc721TotalStaked;
        mapping(address => mapping(address => uint256[])) erc721Stakes;
        
        // ERC1155
        mapping(address => mapping(uint256 => uint256)) erc1155TotalStaked;
        mapping(address => mapping(address => mapping(uint256 => uint256))) erc1155Stakes;
        
        // Common
        mapping(address => uint256) lastClaimTime;
        address[] supportedTokens;
    }

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}