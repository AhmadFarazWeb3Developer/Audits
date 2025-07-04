// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {WeakRandomness} from "../src/WeakRandomness.sol";

contract WeakRandomnessTest is Test {
    WeakRandomness public weakRandomness;

    function setUp() public {
        weakRandomness = new WeakRandomness();
    }

    function test_randomNumber() public view {
        console.log(weakRandomness.getRandomNumber());
    }
}
