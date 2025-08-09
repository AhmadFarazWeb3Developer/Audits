// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol"; // actual smart wallet
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol"; // delegate calls to different version of singlton smart wallet
// import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol"; // Register the Safeproxies
import {WalletRegistry} from "../src/WalletRegistry.sol";
import {UtilsTest} from "./Utils.t.sol";

contract WalletRegistryTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testWalletRegistry() public {}
    function testProxyCreated() public {
        vm.startPrank(address(proxyFactory));

        // Encode the setup data
        address[] memory owners = new address[](1);
        owners[0] = alice;

        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            1,
            address(0),
            "",
            address(0),
            address(token),
            0,
            alice
        );

        // creating the actual wallet via Proxy Factory
        SafeProxy proxy = proxyFactory.createProxyWithNonce(
            address(smartWallet),
            initializer,
            0 // saltNonce
        );

        walletRegistry.proxyCreated(
            proxy,
            address(smartWallet),
            initializer,
            0
        );

        vm.stopPrank();
        token.balanceOf(address(proxy));

        // vm.startPrank(address(proxy));
        // token.approve(address(proxy), 10 ether);
        // token.transferFrom(address(proxy), charlie, 10 ether);
        // token.balanceOf(charlie);
    }

    function testAttack() public {
        backdoor.attack();
    }
}
