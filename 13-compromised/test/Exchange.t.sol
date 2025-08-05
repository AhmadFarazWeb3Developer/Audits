// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";

contract ExchangeTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testExchange() public view {}
}
