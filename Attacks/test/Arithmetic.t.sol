// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {Overflow, Underflow, PrecisionLoss} from "../src/Arithmetic.sol";

contract ArithmeticTest is Test {
    Overflow public overflow;
    Underflow public underflow;
    PrecisionLoss public precisionLoss;

    function setUp() public {
        overflow = new Overflow();
        underflow = new Underflow();
        precisionLoss = new PrecisionLoss();
    }

    function test_increment() public {
        overflow.increment(26);
        console.log(overflow.count());
        overflow.increment(255);
        console.log(overflow.count()); // 26 + 255= 25 because 26 wrapps arround and start from 0
    }

    function test_decrement() public {
        underflow.decrement(1);
        console.log(underflow.count());
    }

    function test_precisionLoss() public {
        console.log(precisionLoss.shareMoney());
    }
}
