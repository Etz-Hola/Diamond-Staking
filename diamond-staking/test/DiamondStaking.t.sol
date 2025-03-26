// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../src/contracts/Diamond.sol";
import {ERC20Facet} from "../src/contracts/facets/ERC20Facet.sol";
import {ERC721Facet} from "../src/contracts/facets/ERC721Facet.sol";
import {ERC1155Facet} from "../src/contracts/facets/ERC1155Facet.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC1155} from "./mocks/MockERC1155.sol";

contract DiamondStakingTest is Test {
    Diamond public diamond;
    ERC20Facet public erc20Facet;
    ERC721Facet public erc721Facet;
    ERC1155Facet public erc1155Facet;
    MockERC20 public mockERC20;
    MockERC721 public mockERC721;
    MockERC1155 public mockERC1155;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        // Deploy Diamond
        diamond = new Diamond();

        // Deploy facets
        erc20Facet = new ERC20Facet();
        erc721Facet = new ERC721Facet();
        erc1155Facet = new ERC1155Facet();

        // Deploy mock tokens
        mockERC20 = new MockERC20("Mock ERC20", "MERC20");
        mockERC721 = new MockERC721("Mock ERC721", "MERC721");
        mockERC1155 = new MockERC1155();

        // Mint tokens to users
        mockERC20.mint(user1, 1000 ether);
        mockERC20.mint(user2, 1000 ether);
        mockERC721.mint(user1, 1);
        mockERC721.mint(user2, 2);
        mockERC1155.mint(user1, 1, 100, "");
        mockERC1155.mint(user2, 1, 100, "");

        // Approve tokens
        vm.prank(user1);
        mockERC20.approve(address(diamond), type(uint256).max);
        vm.prank(user2);
        mockERC20.approve(address(diamond), type(uint256).max);
        vm.prank(user1);
        mockERC721.setApprovalForAll(address(diamond), true);
        vm.prank(user2);
        mockERC721.setApprovalForAll(address(diamond), true);
        vm.prank(user1);
        mockERC1155.setApprovalForAll(address(diamond), true);
        vm.prank(user2);
        mockERC1155.setApprovalForAll(address(diamond), true);
    }

    function testStakeERC20() public {
        vm.prank(user1);
        diamond.stakeERC20(address(mockERC20), 100 ether);
        assertEq(diamond.getStakedAmount(user1, address(mockERC20)), 100 ether);
    }

    function testUnstakeERC20() public {
        vm.prank(user1);
        diamond.stakeERC20(address(mockERC20), 100 ether);
        vm.warp(block.timestamp + 8 days); // Pass minimum staking period
        vm.prank(user1);
        diamond.unstakeERC20(address(mockERC20), 50 ether);
        assertEq(diamond.getStakedAmount(user1, address(mockERC20)), 50 ether);
    }

    function testStakeERC721() public {
        vm.prank(user1);
        diamond.stakeERC721(address(mockERC721), 1);
        assertTrue(diamond.isNFTStaked(user1, 1));
    }

    function testUnstakeERC721() public {
        vm.prank(user1);
        diamond.stakeERC721(address(mockERC721), 1);
        vm.warp(block.timestamp + 8 days); // Pass minimum staking period
        vm.prank(user1);
        diamond.unstakeERC721(address(mockERC721), 1);
        assertFalse(diamond.isNFTStaked(user1, 1));
    }

    function testStakeERC1155() public {
        vm.prank(user1);
        diamond.stakeERC1155(address(mockERC1155), 1, 50);
        assertEq(diamond.getERC1155StakedAmount(user1, 1), 50);
    }

    function testUnstakeERC1155() public {
        vm.prank(user1);
        diamond.stakeERC1155(address(mockERC1155), 1, 50);
        vm.warp(block.timestamp + 8 days); // Pass minimum staking period
        vm.prank(user1);
        diamond.unstakeERC1155(address(mockERC1155), 1, 25);
        assertEq(diamond.getERC1155StakedAmount(user1, 1), 25);
    }

    function testRewardsCalculation() public {
        vm.prank(user1);
        diamond.stakeERC20(address(mockERC20), 100 ether);
        vm.warp(block.timestamp + 30 days); // Pass 30 days
        uint256 rewards = diamond.calculateRewards(user1, address(mockERC20));
        assertTrue(rewards > 0);
    }

    function testClaimRewards() public {
        vm.prank(user1);
        diamond.stakeERC20(address(mockERC20), 100 ether);
        vm.warp(block.timestamp + 30 days); // Pass 30 days
        vm.prank(user1);
        diamond.claimRewards(address(mockERC20));
        assertEq(diamond.getStakedAmount(user1, address(diamond)), diamond.calculateRewards(user1, address(mockERC20)));
    }

    function testFailUnstakeBeforeMinDuration() public {
        vm.prank(user1);
        diamond.stakeERC20(address(mockERC20), 100 ether);
        vm.prank(user1);
        diamond.unstakeERC20(address(mockERC20), 50 ether);
    }

    function testFailUnstakeMoreThanStaked() public {
        vm.prank(user1);
        diamond.stakeERC20(address(mockERC20), 100 ether);
        vm.warp(block.timestamp + 8 days);
        vm.prank(user1);
        diamond.unstakeERC20(address(mockERC20), 150 ether);
    }
} 