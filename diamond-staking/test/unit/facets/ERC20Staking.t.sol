// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/contracts/diamond/Diamond.sol";
import "../../src/contracts/facets/ERC20StakingFacet.sol";
import "../../src/contracts/facets/ERC20Facet.sol";

contract ERC20StakingTest is Test {
    Diamond diamond;
    ERC20StakingFacet stakingFacet;
    
    function setUp() public {
        // Deploy diamond and facets
        diamond = new Diamond(address(this), address(0));
        stakingFacet = new ERC20StakingFacet();
        
        // Cut the facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ERC20StakingFacet.stakeERC20.selector;
        selectors[1] = ERC20StakingFacet.unstakeERC20.selector;
        
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(stakingFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
    }

    function testStakeERC20() public {
        // Test implementation
    }
}