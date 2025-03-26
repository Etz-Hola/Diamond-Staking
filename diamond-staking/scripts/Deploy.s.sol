// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Diamond} from "../src/contracts/Diamond.sol";
import {ERC20Facet} from "../src/contracts/facets/ERC20Facet.sol";
import {ERC721Facet} from "../src/contracts/facets/ERC721Facet.sol";
import {ERC1155Facet} from "../src/contracts/facets/ERC1155Facet.sol";
import {DiamondCut} from "../src/contracts/libraries/DiamondCut.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Diamond
        Diamond diamond = new Diamond();

        // Deploy facets
        ERC20Facet erc20Facet = new ERC20Facet();
        ERC721Facet erc721Facet = new ERC721Facet();
        ERC1155Facet erc1155Facet = new ERC1155Facet();

        // Add facets to Diamond
        bytes4[] memory erc20Selectors = new bytes4[](8);
        erc20Selectors[0] = ERC20Facet.stakeERC20.selector;
        erc20Selectors[1] = ERC20Facet.unstakeERC20.selector;
        erc20Selectors[2] = ERC20Facet.claimRewards.selector;
        erc20Selectors[3] = ERC20Facet.calculateRewards.selector;
        erc20Selectors[4] = ERC20Facet.getStakedAmount.selector;
        erc20Selectors[5] = ERC20Facet.getTotalStaked.selector;
        erc20Selectors[6] = ERC20Facet.getStakingTimestamp.selector;
        erc20Selectors[7] = ERC20Facet.getLastRewardClaim.selector;

        bytes4[] memory erc721Selectors = new bytes4[](7);
        erc721Selectors[0] = ERC721Facet.stakeERC721.selector;
        erc721Selectors[1] = ERC721Facet.unstakeERC721.selector;
        erc721Selectors[2] = ERC721Facet.claimNFTRewards.selector;
        erc721Selectors[3] = ERC721Facet.calculateNFTRewards.selector;
        erc721Selectors[4] = ERC721Facet.getStakedNFTCount.selector;
        erc721Selectors[5] = ERC721Facet.isNFTStaked.selector;

        bytes4[] memory erc1155Selectors = new bytes4[](7);
        erc1155Selectors[0] = ERC1155Facet.stakeERC1155.selector;
        erc1155Selectors[1] = ERC1155Facet.unstakeERC1155.selector;
        erc1155Selectors[2] = ERC1155Facet.claimERC1155Rewards.selector;
        erc1155Selectors[3] = ERC1155Facet.calculateERC1155Rewards.selector;
        erc1155Selectors[4] = ERC1155Facet.getTotalERC1155Staked.selector;
        erc1155Selectors[5] = ERC1155Facet.getERC1155StakedAmount.selector;

        // Add facets to Diamond
        DiamondCut.addFunctions(address(erc20Facet), erc20Selectors);
        DiamondCut.addFunctions(address(erc721Facet), erc721Selectors);
        DiamondCut.addFunctions(address(erc1155Facet), erc1155Selectors);

        vm.stopBroadcast();
    }
} 