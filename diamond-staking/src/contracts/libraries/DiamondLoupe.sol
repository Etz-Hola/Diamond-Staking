// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DiamondCut} from "./DiamondCut.sol";

library DiamondLoupe {
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition;
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition;
    }

    struct FacetAddressAndFunctionSelectors {
        address facetAddress;
        FacetFunctionSelectors f;
    }

    struct DiamondLoupeStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        bytes4[] selectors;
        uint256 selectorCount;
    }

    function diamondStorage() internal pure returns (DiamondLoupeStorage storage ds) {
        bytes32 position = keccak256("diamond.standard.diamond.loupe.storage");
        assembly {
            ds.slot := position
        }
    }

    function facetAddressAndPosition(bytes4 _selector) internal view returns (FacetAddressAndPosition memory) {
        DiamondLoupeStorage storage ds = diamondStorage();
        return ds.selectorToFacetAndPosition[_selector];
    }

    function facetAddress(bytes4 _selector) internal view returns (address) {
        return facetAddressAndPosition(_selector).facetAddress;
    }

    function functionSelectorPosition(bytes4 _selector) internal view returns (uint96) {
        return facetAddressAndPosition(_selector).functionSelectorPosition;
    }

    function facetAddresses() internal view returns (address[] memory) {
        DiamondLoupeStorage storage ds = diamondStorage();
        uint256 numFacets = ds.selectorCount;
        address[] memory addresses = new address[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            addresses[i] = ds.selectorToFacetAndPosition[ds.selectors[i]].facetAddress;
        }
        return addresses;
    }

    function functionSelectors(address _facet) internal view returns (bytes4[] memory) {
        DiamondLoupeStorage storage ds = diamondStorage();
        uint256 numSelectors = ds.selectorCount;
        uint256 numFacetSelectors;
        for (uint256 i; i < numSelectors; i++) {
            if (ds.selectorToFacetAndPosition[ds.selectors[i]].facetAddress == _facet) {
                numFacetSelectors++;
            }
        }
        bytes4[] memory selectors = new bytes4[](numFacetSelectors);
        uint256 selectorIndex;
        for (uint256 i; i < numSelectors; i++) {
            if (ds.selectorToFacetAndPosition[ds.selectors[i]].facetAddress == _facet) {
                selectors[selectorIndex] = ds.selectors[i];
                selectorIndex++;
            }
        }
        return selectors;
    }
} 