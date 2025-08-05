// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";

contract TrustfulOracleInitializerTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testOracle() public view {
        trustfulOracle.getAllPricesForSymbol("DVNFT");
    }
}
