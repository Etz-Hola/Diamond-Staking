// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {LibAppStorage} from "../libraries/AppStorage.sol";
import {IDiamondStaking} from "../interfaces/IDiamondStaking.sol";

contract StakingFacet is IDiamondStaking {
    using LibAppStorage for LibAppStorage.AppStorage;

    modifier whenNotPaused() {
        require(!LibAppStorage.diamondStorage().paused, "Contract is paused");
        _;
    }

    modifier onlyAdmin() {
        require(LibAppStorage.diamondStorage().isAdmin[msg.sender], "Not authorized");
        _;
    }

    function stakeERC20(address token, uint256 amount) external override whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        AppStorage storage s = LibAppStorage.diamondStorage();
        StakingInfo storage stake = s.erc20Stakes[msg.sender][token];
        
        // Transfer tokens from user
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        // Update staking info
        stake.amount += amount;
        stake.lastUpdateTime = block.timestamp;
        s.totalStakedERC20[token] += amount;
        
        emit Staked(msg.sender, token, 0, amount);
    }

    function stakeERC721(address token, uint256 tokenId) external override whenNotPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        NFTStakingInfo storage stake = s.erc721Stakes[msg.sender][token];
        
        // Transfer NFT from user
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        
        // Update staking info
        stake.stakedTokenIds.push(tokenId);
        stake.lastUpdateTime = block.timestamp;
        s.totalStakedERC721[token] += 1;
        
        emit Staked(msg.sender, token, tokenId, 1);
    }

    function stakeERC1155(address token, uint256 tokenId, uint256 amount) external override whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        AppStorage storage s = LibAppStorage.diamondStorage();
        ERC1155StakingInfo storage stake = s.erc1155Stakes[msg.sender][token];
        
        // Transfer tokens from user
        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        
        // Update staking info
        stake.stakedAmounts[tokenId] += amount;
        stake.lastUpdateTime = block.timestamp;
        s.totalStakedERC1155[token] += amount;
        
        emit Staked(msg.sender, token, tokenId, amount);
    }

    function unstakeERC20(address token, uint256 amount) external override whenNotPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        StakingInfo storage stake = s.erc20Stakes[msg.sender][token];
        
        require(stake.amount >= amount, "Insufficient staked amount");
        
        // Update staking info
        stake.amount -= amount;
        stake.lastUpdateTime = block.timestamp;
        s.totalStakedERC20[token] -= amount;
        
        // Transfer tokens back to user
        IERC20(token).transfer(msg.sender, amount);
        
        emit Unstaked(msg.sender, token, 0, amount);
    }

    function unstakeERC721(address token, uint256 tokenId) external override whenNotPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        NFTStakingInfo storage stake = s.erc721Stakes[msg.sender][token];
        
        // Find and remove tokenId from array
        for (uint256 i = 0; i < stake.stakedTokenIds.length; i++) {
            if (stake.stakedTokenIds[i] == tokenId) {
                stake.stakedTokenIds[i] = stake.stakedTokenIds[stake.stakedTokenIds.length - 1];
                stake.stakedTokenIds.pop();
                break;
            }
        }
        
        stake.lastUpdateTime = block.timestamp;
        s.totalStakedERC721[token] -= 1;
        
        // Transfer NFT back to user
        IERC721(token).transferFrom(address(this), msg.sender, tokenId);
        
        emit Unstaked(msg.sender, token, tokenId, 1);
    }

    function unstakeERC1155(address token, uint256 tokenId, uint256 amount) external override whenNotPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        ERC1155StakingInfo storage stake = s.erc1155Stakes[msg.sender][token];
        
        require(stake.stakedAmounts[tokenId] >= amount, "Insufficient staked amount");
        
        // Update staking info
        stake.stakedAmounts[tokenId] -= amount;
        stake.lastUpdateTime = block.timestamp;
        s.totalStakedERC1155[token] -= amount;
        
        // Transfer tokens back to user
        IERC1155(token).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        
        emit Unstaked(msg.sender, token, tokenId, amount);
    }

    function claimRewards() external override whenNotPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 rewards = calculateRewards(msg.sender);
        
        require(rewards > 0, "No rewards to claim");
        
        // Transfer rewards
        IERC20(s.diamondToken).transfer(msg.sender, rewards);
        
        emit RewardsClaimed(msg.sender, rewards);
    }

    function getRewards(address user) external view override returns (uint256) {
        return calculateRewards(user);
    }

    function getStakedBalance(address user, address token) external view override returns (uint256) {
        return LibAppStorage.diamondStorage().erc20Stakes[user][token].amount;
    }

    function getStakedNFTs(address user, address token) external view override returns (uint256[] memory) {
        return LibAppStorage.diamondStorage().erc721Stakes[user][token].stakedTokenIds;
    }

    function getStakedERC1155Balance(address user, address token, uint256 tokenId) external view override returns (uint256) {
        return LibAppStorage.diamondStorage().erc1155Stakes[user][token].stakedAmounts[tokenId];
    }

    function setRewardRate(uint256 newRate) external override onlyAdmin {
        LibAppStorage.diamondStorage().rewardRate = newRate;
    }

    function setDecayRate(uint256 newRate) external override onlyAdmin {
        LibAppStorage.diamondStorage().decayRate = newRate;
    }

    function pause() external override onlyAdmin {
        LibAppStorage.diamondStorage().paused = true;
    }

    function unpause() external override onlyAdmin {
        LibAppStorage.diamondStorage().paused = false;
    }

    // Internal functions
    function calculateRewards(address user) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 rewards = 0;
        
        // Calculate ERC20 rewards
        for (uint256 i = 0; i < s.totalStakedERC20[address(0)]; i++) {
            StakingInfo storage stake = s.erc20Stakes[user][address(0)];
            if (stake.amount > 0) {
                uint256 timeStaked = block.timestamp - stake.lastUpdateTime;
                uint256 reward = (stake.amount * s.rewardRate * timeStaked) / 1e18;
                rewards += reward;
            }
        }
        
        // Calculate ERC721 rewards
        for (uint256 i = 0; i < s.totalStakedERC721[address(0)]; i++) {
            NFTStakingInfo storage stake = s.erc721Stakes[user][address(0)];
            if (stake.stakedTokenIds.length > 0) {
                uint256 timeStaked = block.timestamp - stake.lastUpdateTime;
                uint256 reward = (stake.stakedTokenIds.length * s.rewardRate * timeStaked) / 1e18;
                rewards += reward;
            }
        }
        
        // Calculate ERC1155 rewards
        for (uint256 i = 0; i < s.totalStakedERC1155[address(0)]; i++) {
            ERC1155StakingInfo storage stake = s.erc1155Stakes[user][address(0)];
            for (uint256 j = 0; j < stake.stakedAmounts[0]; j++) {
                uint256 timeStaked = block.timestamp - stake.lastUpdateTime;
                uint256 reward = (stake.stakedAmounts[0] * s.rewardRate * timeStaked) / 1e18;
                rewards += reward;
            }
        }
        
        return rewards;
    }
} 