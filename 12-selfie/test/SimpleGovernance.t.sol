// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";

contract SimpleGovernanceTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testVotesSupply() public view {
        assertEq(dvtVotes.totalSupply(), 1500000 ether);
    }

    function testQueueAction() public {
        // 1000000 000 000 000 000 000 000
        // 1500000 000 000 000 000 000 000

        // dvtVotes.approve(address(target), 1000000 ether);
        dvtVotes.transfer(address(target), 1000000 ether);

        // Activate voting power
        vm.startPrank(address(target));
        dvtVotes.delegate(address(target));
        dvtVotes.getVotes(address(target));
        simpleGovernance.queueAction(address(target), 1000000 ether, "");
        simpleGovernance.executeAction(1);
    }
}
