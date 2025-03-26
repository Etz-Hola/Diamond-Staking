// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library AppStorage {
    bytes32 constant STORAGE_SLOT = keccak256("diamond.staking.storage");

    struct Layout {
        // Token addresses
        address rewardToken;
        
        // Staking parameters
        uint256 rewardRate;      // Base reward rate (in basis points)
        uint256 decayRate;       // Rate at which rewards decay (in basis points)
        uint256 minStakeDuration;
        uint256 maxStakeDuration;
        
        // Staking data
        mapping(address => mapping(address => uint256)) stakedAmount;
        mapping(address => mapping(address => uint256)) stakingTimestamp;
        mapping(address => mapping(address => uint256)) lastRewardClaim;
        mapping(address => mapping(uint256 => uint256)) stakedNFTs;
        mapping(address => mapping(uint256 => uint256)) stakedERC1155;
        
        // Total staked amounts
        mapping(address => uint256) totalStaked;
        
        // Facet addresses
        mapping(bytes4 => address) selectorToFacetAndPosition;
        mapping(address => bool) supportedTokens;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_SLOT;
        assembly {
            l.slot := position
        }
    }
} 