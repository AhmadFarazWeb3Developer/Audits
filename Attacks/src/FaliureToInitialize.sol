// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FaliureToInitialize {
    uint256 public myValue;
    bool public initialized;

    // we can forget to initialize this function
    function initialize(uint256 _startingValue) public {
        myValue = _startingValue;
        initialized = true;
    }

    // We should have a check here to make susre the contract was initialized!

    function increment() public {
        myValue++;
    }
}
