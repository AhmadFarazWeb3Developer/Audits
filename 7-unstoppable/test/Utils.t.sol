// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Mock} from "./Mock/ERC20Mock.sol";
import {ERC20} from "solmate/tokens/ERC4626.sol";

import {UnstoppableVault} from "../src/UnstoppableVault.sol";
import {UnstoppableMonitor} from "../src/UnstoppableMonitor.sol";

contract UtilsTest is Test {
    UnstoppableVault vault;
    UnstoppableMonitor monitor;

    address vaultOwner = makeAddr("vault owner");
    address feeRecepient = makeAddr("fee recepient");
    address flashLoaner = makeAddr("flash Loaner");
    address attacker = makeAddr("Attacker");

    ERC20Mock token;

    function setUp() public virtual {
        token = new ERC20Mock(); // lets USDS token created

        vault = new UnstoppableVault(
            ERC20(address(token)), // lets created for USDC
            vaultOwner,
            feeRecepient
        );

        token.mint(address(this), 20);

        token.approve(address(vault), 10);
        vault.deposit(10, address(this));

        monitor = new UnstoppableMonitor(address(vault));

        vm.startPrank(address(monitor));

        token.mint(address(monitor), 20);

        token.approve(address(vault), 10);

        vm.stopPrank();
    }
}
