// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DiamondCut} from "./libraries/DiamondCut.sol";
import {DiamondLoupe} from "./libraries/DiamondLoupe.sol";
import {AppStorage} from "./libraries/AppStorage.sol";

contract Diamond {
    AppStorage.Layout internal l;

    constructor() {
        // Initialize storage
        l.rewardToken = address(this);
        l.rewardRate = 100; // 1% per day
        l.decayRate = 5; // 0.05% per day
        l.minStakeDuration = 7 days;
        l.maxStakeDuration = 365 days;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and returns any value.
    fallback() external payable {
        DiamondLoupe.FacetAddressAndPosition memory facetAddressAndPosition = DiamondLoupe
            .facetAddressAndPosition(msg.sig);
        address facet = facetAddressAndPosition.facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
} 