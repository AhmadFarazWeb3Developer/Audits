// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {SimpleGovernance} from "../src/SimpleGovernance.sol";

contract Attack {
    SimpleGovernance simpleGovernance;
    constructor(SimpleGovernance _simpleGovernance) {
        simpleGovernance = _simpleGovernance;
    }
    function functionCallWithValue(
        bytes calldata _data,
        uint256 _value
    ) external payable {
        
    }
}
