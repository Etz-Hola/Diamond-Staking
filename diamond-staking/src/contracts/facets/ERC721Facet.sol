// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AppStorage} from "../libraries/AppStorage.sol";

contract ERC721Facet {
    AppStorage.Layout internal l;

    event NFTStaked(address indexed user, address indexed token, uint256 tokenId);
    event NFTUnstaked(address indexed user, address indexed token, uint256 tokenId);
    event NFTRewardsClaimed(address indexed user, uint256 amount);

    function stakeERC721(address token, uint256 tokenId) external {
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "Not token owner");
        require(IERC721(token).isApprovedForAll(msg.sender, address(this)), "Contract not approved");

        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        
        l.stakedNFTs[msg.sender][tokenId] = 1;
        l.stakingTimestamp[msg.sender][token] = block.timestamp;
        l.lastRewardClaim[msg.sender][token] = block.timestamp;
        l.totalStaked[token] += 1;

        emit NFTStaked(msg.sender, token, tokenId);
    }

    function unstakeERC721(address token, uint256 tokenId) external {
        require(l.stakedNFTs[msg.sender][tokenId] == 1, "NFT not staked");
        require(block.timestamp >= l.stakingTimestamp[msg.sender][token] + l.minStakeDuration, "Staking period not met");

        // Calculate and claim rewards before unstaking
        uint256 rewards = calculateNFTRewards(msg.sender, token);
        if (rewards > 0) {
            _mintRewards(msg.sender, rewards);
        }

        l.stakedNFTs[msg.sender][tokenId] = 0;
        l.totalStaked[token] -= 1;
        l.lastRewardClaim[msg.sender][token] = block.timestamp;

        IERC721(token).transferFrom(address(this), msg.sender, tokenId);

        emit NFTUnstaked(msg.sender, token, tokenId);
    }

    function claimNFTRewards(address token) external {
        uint256 rewards = calculateNFTRewards(msg.sender, token);
        require(rewards > 0, "No rewards to claim");

        _mintRewards(msg.sender, rewards);
        l.lastRewardClaim[msg.sender][token] = block.timestamp;

        emit NFTRewardsClaimed(msg.sender, rewards);
    }

    function calculateNFTRewards(address user, address token) public view returns (uint256) {
        uint256 stakedCount = getStakedNFTCount(user, token);
        if (stakedCount == 0) return 0;

        uint256 timeStaked = block.timestamp - l.lastRewardClaim[user][token];
        uint256 baseReward = (stakedCount * l.rewardRate * timeStaked) / (365 days * 10000);
        
        // Apply decay rate based on time staked
        uint256 totalTimeStaked = block.timestamp - l.stakingTimestamp[user][token];
        uint256 decayFactor = 10000 - (totalTimeStaked * l.decayRate / (365 days * 10000));
        if (decayFactor < 5000) decayFactor = 5000; // Minimum 50% of base reward

        return (baseReward * decayFactor) / 10000;
    }

    function getStakedNFTCount(address user, address token) public view returns (uint256) {
        uint256 count = 0;
        // Note: This is a simplified version. In a real implementation, you'd want to track staked NFTs more efficiently
        for (uint256 i = 0; i < 10000; i++) { // Assuming max 10000 NFTs per collection
            if (l.stakedNFTs[user][i] == 1) {
                count++;
            }
        }
        return count;
    }

    function isNFTStaked(address user, uint256 tokenId) external view returns (bool) {
        return l.stakedNFTs[user][tokenId] == 1;
    }

    function _mintRewards(address to, uint256 amount) internal {
        l.stakedAmount[to][address(this)] += amount;
        l.totalStaked[address(this)] += amount;
    }
} 