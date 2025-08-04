// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {SimpleGovernance} from "../src/SimpleGovernance.sol";
import {DamnValuableVotes} from "../src/DamnValuableVotes.sol";
import {console2} from "forge-std/Test.sol";

contract Attack {
    SimpleGovernance simpleGovernance;

    constructor(SimpleGovernance _simpleGovernance) {
        simpleGovernance = _simpleGovernance;
    }

    // with no matching function selector handles the ETH
    fallback() external payable {}
}
