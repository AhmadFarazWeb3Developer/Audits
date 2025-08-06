// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {SimpleGovernance} from "../src/SimpleGovernance.sol";
import {DamnValuableVotes} from "../src/DamnValuableVotes.sol";

import {Attack} from "./Attack.sol";
import {SelfiePool} from "../src/SelfiePool.sol";

abstract contract UtilsTest is Test {
    SimpleGovernance simpleGovernance;
    DamnValuableVotes dvtVotes;
    Attack target;
    SelfiePool pool;

    function setUp() public virtual {
        dvtVotes = new DamnValuableVotes(1500000 ether);

        simpleGovernance = new SimpleGovernance(dvtVotes);

        pool = new SelfiePool(dvtVotes, simpleGovernance);

        target = new Attack(simpleGovernance, dvtVotes, pool);
        dvtVotes.transfer(address(pool), 1500000 ether);
    }
}
