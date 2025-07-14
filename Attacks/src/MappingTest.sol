// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

contract MappingTest {
    mapping(address => address) public token2token;

    function setAddress(address _token1, address _token2) public {
        token2token[_token1] = _token2;
    }

    function remove(address _token) public {
        delete token2token[_token];
    }
}

// the delete key word works but the chisel has the issue of detetion of mapping
