// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct DiamondStorage {
    // Function selector => facet address and selector position in selectors array
    mapping(bytes4 => bytes32) selectorSlot;
    
    // The number of function selectors in the selectors array
    uint16 selectorCount;
    
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
    
    // Owner of the contract
    address contractOwner;
} 