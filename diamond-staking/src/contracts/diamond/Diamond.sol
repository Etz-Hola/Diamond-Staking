// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DiamondStorage} from "./DiamondStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract Diamond {
    constructor() {
        LibDiamond.diamondStorage().contractOwner = msg.sender;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and returns any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.diamondStoragePosition();
        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.selectorSlot[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
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
