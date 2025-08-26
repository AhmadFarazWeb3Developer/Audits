// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console, console2} from "forge-std/Test.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract AuthorizedExecutor is ReentrancyGuard {
    using Address for address;

    bool public initialized; // 32 bytes

    // action identifier => allowed
    mapping(bytes32 => bool) public permissions; // 32 bytes

    error NotAllowed();
    error AlreadyInitialized();

    event Initialized(address who, bytes32[] ids);

    /**
     * @notice Allows first caller to set permissions for a set of action identifiers
     * @param ids array of action identifiers
     */

    // q can this be called ?

    function setPermissions(bytes32[] memory ids) external {
        if (initialized) {
            revert AlreadyInitialized();
        }

        for (uint256 i = 0; i < ids.length; ) {
            unchecked {
                permissions[ids[i]] = true;
                ++i;
            }
        }
        initialized = true;

        emit Initialized(msg.sender, ids);
    }

    /**
     * @notice Performs an arbitrary function call on a target contract, if the caller is authorized to do so.
     * @param target account where the action will be executed
     * @param actionData abi-encoded calldata to execute on the target
     */
    function execute(
        address target,
        bytes calldata actionData
    ) external nonReentrant returns (bytes memory) {
        // Read the 4-bytes selector at the beginning of `actionData`
        bytes4 selector;
        uint256 calldataOffset = 4 + 32 * 3; // calldata position where `actionData` begins

        assembly {
            selector := calldataload(calldataOffset)
        }
        console.logBytes4(selector);

        if (!permissions[getActionId(selector, msg.sender, target)]) {
            revert NotAllowed();
        }

        _beforeFunctionCall(target, actionData);

        return target.functionCall(actionData);
    }

    function _beforeFunctionCall(
        address target,
        bytes memory actionData
    ) internal virtual;

    function getActionId(
        bytes4 selector,
        address executor,
        address target
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(selector, executor, target));
    }
}

/*
 0xd9caed12
   0000000000000000000000003774dc4617020fbf907eb5538299633b1892534b -> attacker address 0x3774dc4617020fBF907Eb5538299633b1892534b
   0000000000000000000000002e234dae75c793f67a35089c9d99245e1c58470b -> valut address 0x2e234DAe75C793f67A35089C9d99245E1C58470b
   0000000000000000000000000000000000000000000000000000000000000060 -> referece to action data
   000000000000000000000000000000000000000000000000000000000000004485fb709d0000000000000000000000003774dc4617020fbf907eb5538299633b1892534b0000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f00000000000000000000000000000000000000000000000000000000

 */
