// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol"; // actual smart wallet
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol"; // delegate calls to different version of singlton smart wallet
import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol"; // Register the Safeproxies
import {WalletRegistry} from "../src/WalletRegistry.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {BackdoorExploit} from "./Attack.sol";
contract UtilsTest is Test {
    Safe smartWallet;
    SafeProxy proxy;
    SafeProxyFactory proxyFactory;
    WalletRegistry walletRegistry;
    DamnValuableToken token;

    BackdoorExploit backdoor;
    address alice;
    address bob;
    address charlie;
    address david;

    function setUp() public virtual {
        // Safe Singleton (depolyed once)
        smartWallet = new Safe();

        // Create proxies (the actual wallet using Safe)
        proxyFactory = new SafeProxyFactory();

        token = new DamnValuableToken();

        address[] memory beneficiaries = new address[](4);

        beneficiaries[0] = makeAddr("Alice");
        beneficiaries[1] = makeAddr("Bob");
        beneficiaries[2] = makeAddr("Charlie");
        beneficiaries[3] = makeAddr("David");

        alice = beneficiaries[0];
        bob = beneficiaries[1];
        charlie = beneficiaries[2];
        david = beneficiaries[3];

        walletRegistry = new WalletRegistry(
            address(smartWallet),
            address(proxyFactory),
            address(token),
            beneficiaries
        );

        token.transfer(address(walletRegistry), 40 ether);
        token.approve(address(walletRegistry), type(uint256).max);

        backdoor = new BackdoorExploit(
            smartWallet,
            proxyFactory,
            token,
            walletRegistry,
            beneficiaries,
            alice,
            40 ether
        );
    }
}
