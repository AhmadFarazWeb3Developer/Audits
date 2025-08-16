// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";
import {ClimberVault} from "../src/ClimberVault.sol";

contract ClimberVaultTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function test_Initialization() public {
        ClimberVault proxy = ClimberVault(address(erc1967Proxy));

        bytes32 slot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );

        bytes32 implBytes = vm.load(address(erc1967Proxy), slot);

        address slotAddress = address(uint160(uint256(implBytes)));

        assertEq(slotAddress, address(valut));
    }
}
