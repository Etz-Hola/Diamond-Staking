// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DiamondStorage} from "../diamond/DiamondStorage.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function diamondStoragePosition() internal pure returns (bytes32) {
        return DIAMOND_STORAGE_POSITION;
    }
}
