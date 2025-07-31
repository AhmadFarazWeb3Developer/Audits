// SPDX-License-Identifier: MIT

pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

import {Owned} from "solmate/auth/Owned.sol";

import {UnstoppableVault, ERC20} from "./UnstoppableVault.sol";

/**
 * @notice Permissioned contract for on-chain monitoring of the vault's flashloan feature.
 */

contract UnstoppableMonitor is Owned, IERC3156FlashBorrower {
    // e vault contract reference

    UnstoppableVault private immutable vault;

    error UnexpectedFlashLoan();
    error SameInitiator();
    error VaultContractCaller();
    error AssetToken();
    error ZeroFee();

    event FlashLoanStatus(bool success);

    constructor(address _vault) Owned(msg.sender) {
        vault = UnstoppableVault(_vault);
    }

    // e appoving a vault to spend

    /**
     *  initiator: The initiator of the loan.
     *  token: The loan currency.
     *  amount: The amount of tokens lent.
     *  fee: The additional amount of tokens to repay.
     *  data: Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        if (
            //     // e not this contract
            initiator != address(this) ||
            //     // e not the vault contract
            msg.sender != address(vault) ||
            //     // token must not be not be same
            token != address(vault.asset()) // ||
            //  @audit-high no one can withdraw before grace period
            //     fee != 0
        ) {
            revert UnexpectedFlashLoan();
        }

        if (fee == 0) {
            ERC20(token).approve(address(vault), amount);
            return keccak256("IERC3156FlashBorrower.onFlashLoan");
        } else {
            //@audit-high always revert,
            ERC20(token).approve(address(vault), amount + fee);
            return keccak256("IERC3156FlashBorrower.onFlashLoan");
        }
    }

    function checkFlashLoan(uint256 amount) external onlyOwner {
        require(amount > 0);

        address asset = address(vault.asset());

        try vault.flashLoan(this, asset, amount, bytes("")) {
            emit FlashLoanStatus(true);
        } catch {
            // Something bad happened
            emit FlashLoanStatus(false);

            // Pause the vault
            vault.setPause(true);

            // Transfer ownership to allow review & fixes
            vault.transferOwnership(owner);
        }
    }
}
