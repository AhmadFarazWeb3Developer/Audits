// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {Victam, Attacker} from "../src/Reentrancy.sol";

contract VictamTest is Test {
    Victam public victam;
    Attacker public attacker;

    function setUp() public {
        victam = new Victam();
        vm.deal(address(victam), 150 ether);

        attacker = new Attacker(victam);
        vm.deal(address(attacker), 10 ether);
    }

    function test_attack() public {
        console.log("Before Attack");
        console.log("Victim contract amount :", address(victam).balance);
        console.log("Attacker contract amount :", address(attacker).balance);
        attacker.attack();

        console.log("After Attack");
        console.log("Victim contract amount :", address(victam).balance);
        console.log("Attacker contract amount :", address(attacker).balance);
    }
}
