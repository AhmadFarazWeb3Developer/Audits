// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Victam, Attacker} from "../src//Reentrancy.sol";

contract ReentrancyScript is Script {
    Victam public victam;
    Attacker public attacker;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        victam = new Victam();
        attacker = new Attacker(victam);
        vm.stopBroadcast();
    }
}
