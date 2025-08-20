// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";
contract WalletDeployerTest is UtilsTest {
    function setUp() public override {
        super.setUp();
    }

    function test_rule() public {
        address rule = makeAddr("rule");
        vm.expectRevert("Boom()");
        walletDeployer.rule(rule);
    }

    function testFindNonceAndDeploy() public {
        bytes memory wat = buildWat();

        uint256 foundNonce = type(uint256).max;

        vm.pauseGasMetering();
        for (uint256 i = 0; i < 1e6; i++) {
            address predicted = computeAddress(wat, i);
            if (predicted == TARGET_AIM) {
                foundNonce = i;
                console.log("Found nonce:", i);
                break;
            }
        }
        vm.resumeGasMetering();
        require(foundNonce != type(uint256).max, "Nonce not found!");

        // deploy the Safe at the exact lost address
        walletDeployer.drop(TARGET_AIM, wat, foundNonce);

        console.log("Safe recovered at:", TARGET_AIM);
    }
}
