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
        trustfulOracle.getPriceBySource("DVNFT", source1);
        trustfulOracle.getMedianPrice("DVNFT");
    }

    function testPostPrice() public {
        trustfulOracle.postPrice("DVNFT", 1000 ether);
    }

    
}
