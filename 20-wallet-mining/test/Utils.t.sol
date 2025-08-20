// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AuthorizerFactory} from "../src/AuthorizerFactory.sol";
import {WalletDeployer} from "../src/WalletDeployer.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

import {SafeProxyFactory} from "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {SafeProxy} from "safe-smart-account/contracts/proxies/SafeProxy.sol";
import {Safe} from "safe-smart-account/contracts/Safe.sol";

abstract contract UtilsTest is Test {
    AuthorizerFactory authorizerFactory;

    WalletDeployer walletDeployer;
    DamnValuableToken token;

    SafeProxyFactory safeProxyFactory;
    Safe safe;

    address[] wards = new address[](2);
    address[] aims = new address[](2);

    address upgrader = makeAddr("upgrader");

    address[] owners = new address[](1);
    address constant TARGET_AIM = 0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496;
    // function setUp() public virtual {
    //     authorizerFactory = new AuthorizerFactory();

    //     wards[0] = makeAddr("ward1");
    //     wards[1] = makeAddr("ward2");

    //     aims[0] = makeAddr("aim1");
    //     aims[1] = makeAddr("aim2");

    //     owners[0] = vm.addr(1);

    //     bytes memory wat = abi.encodeWithSignature(
    //         "setup(address[],uint256,address,bytes,address,address,uint256,address)",
    //         owners,
    //         1, // threshold = 1
    //         address(0), // to
    //         bytes(""), // data
    //         address(0), // fallbackHandler
    //         address(0), // paymentToken
    //         0, // payment
    //         address(0) // paymentReceiver
    //     );

    //     authorizerFactory.deployWithProxy(wards, aims, upgrader);

    //     token = new DamnValuableToken();
    //     safeProxyFactory = new SafeProxyFactory();

    //     safe = new Safe();

    //     walletDeployer = new WalletDeployer(
    //         address(token),
    //         address(safeProxyFactory),
    //         address(safe),
    //         upgrader
    //     );
    // }

    function setUp() public virtual {
        authorizerFactory = new AuthorizerFactory();

        wards[0] = makeAddr("ward1");
        wards[1] = makeAddr("ward2");

        aims[0] = makeAddr("aim1");
        aims[1] = makeAddr("aim2");

        owners[0] = vm.addr(1);

        authorizerFactory.deployWithProxy(wards, aims, upgrader);

        token = new DamnValuableToken();
        safeProxyFactory = new SafeProxyFactory();
        safe = new Safe();

        walletDeployer = new WalletDeployer(
            address(token),
            address(safeProxyFactory),
            address(safe),
            upgrader
        );
    }

    /// build wat payload for Safe setup 
    function buildWat() internal view returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1, // threshold
                address(0), // to
                bytes(""), // data
                address(0), // fallbackHandler
                address(0), // paymentToken
                0, // payment
                address(0) // paymentReceiver
            );
    }

    /// compute predicted SafeProxy address from factory+salt
    function computeAddress(
        bytes memory initializer,
        uint256 saltNonce
    ) public view returns (address) {
        bytes32 salt = keccak256(abi.encode(keccak256(initializer), saltNonce));

        bytes memory deploymentData = abi.encodePacked(
            type(SafeProxy).creationCode,
            abi.encode(address(safe))
        );

        bytes32 initCodeHash = keccak256(deploymentData);

        bytes32 raw = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(safeProxyFactory),
                salt,
                initCodeHash
            )
        );

        return address(uint160(uint256(raw)));
    }
}
