// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";
import {ClimberVault} from "../src/ClimberVault.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {Attack} from "./Attack.sol";

contract ClimberVaultTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    modifier onlyAdmin() {
        vm.startPrank(getProxy().owner()); //ClimberTimeLock is the actual owner of Climber Vault
        _;
    }

    function getProxy() public returns (ClimberVault) {
        ClimberVault proxy = ClimberVault(address(erc1967Proxy));
        return proxy;
    }

    function test_Initialization() public {
        bytes32 slot = bytes32(
            uint256(keccak256("eip1967.proxy.implementation")) - 1
        );

        bytes32 implBytes = vm.load(address(erc1967Proxy), slot);

        address slotAddress = address(uint160(uint256(implBytes)));

        assertEq(slotAddress, address(valut));
    }

    function test_Withdraw() public onlyAdmin {
        address recipient = makeAddr("recipient");

        vm.warp(block.timestamp + 16 days);
        token.balanceOf(address(valut));
        getProxy().withdraw(address(token), recipient, 1 ether);
    }

    function test_SweepFunds() public {
        vm.startPrank(sweeper);
        getProxy().sweepFunds(address(token));
        assertEq(token.balanceOf(address(erc1967Proxy)), 0);
    }

    function test_Attack() public {
        address recovery = makeAddr("recovery Address");
        Attack attacker = new Attack(
            getProxy(),
            climberTimelock,
            address(token),
            recovery
        );
        attacker.attack();
    }
}
