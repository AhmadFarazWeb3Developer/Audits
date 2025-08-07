// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";
import {AttackerContract} from "./Attack.sol";

contract PuppetPoolTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testPuppetPool() public {
        // 1. Deploy attacker contract with 25 ETH
        AttackerContract attacker = new AttackerContract{value: 25 ether}(
            address(dvt),
            exchange,
            address(pool)
        );

        // 2. Transfer 1000 DVT to attacker contract
        dvt.transfer(address(attacker), 1000 ether);

        // 3. Execute attack
        attacker.attack();

        // 4. Assertions
        assertEq(dvt.balanceOf(address(attacker)), 11000 ether); // 1000 initial + 10000 drained
        assertEq(dvt.balanceOf(address(pool)), 0); // Pool drained
    }
}
