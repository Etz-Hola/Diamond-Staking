// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDiamondStaking {
    // Staking Events
    event Staked(address indexed user, address indexed token, uint256 tokenId, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 tokenId, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    // Staking Functions
    function stakeERC20(address token, uint256 amount) external;
    function stakeERC721(address token, uint256 tokenId) external;
    function stakeERC1155(address token, uint256 tokenId, uint256 amount) external;
    
    function unstakeERC20(address token, uint256 amount) external;
    function unstakeERC721(address token, uint256 tokenId) external;
    function unstakeERC1155(address token, uint256 tokenId, uint256 amount) external;
    
    // Reward Functions
    function claimRewards() external;
    function getRewards(address user) external view returns (uint256);
    
    // View Functions
    function getStakedBalance(address user, address token) external view returns (uint256);
    function getStakedNFTs(address user, address token) external view returns (uint256[] memory);
    function getStakedERC1155Balance(address user, address token, uint256 tokenId) external view returns (uint256);
    
    // Admin Functions
    function setRewardRate(uint256 newRate) external;
    function setDecayRate(uint256 newRate) external;
    function pause() external;
    function unpause() external;
} 