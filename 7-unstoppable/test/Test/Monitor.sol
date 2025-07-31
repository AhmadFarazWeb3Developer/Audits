// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Mock} from "../Mock/ERC20Mock.sol";
import {ERC20} from "solmate/tokens/ERC4626.sol";
import {UtilsTest} from "../Utils.t.sol";
contract MonitorTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testonFlashLoan() public {
        console2.log("Moniter Balance : ", token.balanceOf(address(monitor)));
    }
}
