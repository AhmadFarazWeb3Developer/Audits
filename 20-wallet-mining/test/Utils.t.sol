// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AuthorizerFactory} from "../src/AuthorizerFactory.sol";

abstract contract UtilsTest is Test {
    AuthorizerFactory authorizerFactory;

    address[] wards = new address[](2);
    address[] aims = new address[](2);

    address upgrader = makeAddr("upgrader");

    function setUp() public virtual {
        authorizerFactory = new AuthorizerFactory();

        wards[0] = makeAddr("ward1");
        wards[1] = makeAddr("ward2");

        aims[0] = makeAddr("aim1");
        aims[1] = makeAddr("aim2");

        authorizerFactory.deployWithProxy(wards, aims, upgrader);
    }
}
