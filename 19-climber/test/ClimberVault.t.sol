// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";

contract ClimberVaultTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testWithdraw() public {
        address attacker = makeAddr("attacker");
        vm.startPrank(attacker);
        valut.initialize(attacker, attacker, attacker);
    }
}
