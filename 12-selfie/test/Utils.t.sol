// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {SimpleGovernance} from "../src/SimpleGovernance.sol";
import {DamnValuableVotes} from "../src/DamnValuableVotes.sol";
import {Attack} from "./Attack.sol";

abstract contract UtilsTest is Test {
    SimpleGovernance simpleGovernance;
    DamnValuableVotes dvtVotes;
    Attack target;

    function setUp() public virtual {
        dvtVotes = new DamnValuableVotes(1500000 ether);
        simpleGovernance = new SimpleGovernance(dvtVotes);

        target = new Attack(simpleGovernance);
    }
}
