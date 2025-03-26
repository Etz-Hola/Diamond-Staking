// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AppStorage} from "./AppStorage.sol";

library DiamondCut {
    event DiamondCut(
        address[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant DIAMOND_CUT_STORAGE_POSITION = keccak256("diamond.standard.diamond.cut.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition;
    }

    struct DiamondCutStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        bytes4[] selectors;
        uint256 selectorCount;
    }

    function diamondStorage() internal pure returns (DiamondCutStorage storage ds) {
        bytes32 position = DIAMOND_CUT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        DiamondCutStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectorCount;
        require(_facetAddress != address(0), "DiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "DiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "DiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorCount, _facetAddress);
            selectorCount++;
        }
        ds.selectorCount = selectorCount;
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        DiamondCutStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "DiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "DiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "DiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, ds.selectorCount, _facetAddress);
            ds.selectorCount++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        DiamondCutStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), "DiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFunction(
        DiamondCutStorage storage ds,
        bytes4 selector,
        uint256 selectorCount,
        address facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[selector] = FacetAddressAndPosition(facetAddress, uint96(selectorCount));
        ds.selectors[selectorCount] = selector;
    }

    function removeFunction(
        DiamondCutStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "DiamondCut: Can't remove function that doesn't exist");
        require(_facetAddress != address(this), "DiamondCut: Can't remove self function");
        // Replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.selectorCount - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.selectors[lastSelectorPosition];
            ds.selectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.selectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "DiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "DiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "DiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    assembly {
                        let returndata_size := mload(error)
                        revert(add(32, error), returndata_size)
                    }
                } else {
                    revert("DiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
} 