// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract FlashLoanPool is ReentrancyGuard {
    using Address for address payable;

    bytes32 private constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    error NotEnoughETH();
    error CallbackFailed();
    error RepayFailed();

    event LoanGranted(address indexed receiver, uint256 amount);
    event LoanRepayed(address indexed receiver, uint256 amount);

    function flashLoan(
        IERC3156FlashBorrower receiver,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        uint256 initialBalance = address(this).balance;

        if (amount > initialBalance) {
            revert NotEnoughETH();
        }

        emit LoanGranted(address(receiver), amount);

        // Send ETH to receiver
        payable(address(receiver)).sendValue(amount);

        // Call the borrower's callback
        if (
            receiver.onFlashLoan(msg.sender, address(this), amount, 0, data) !=
            CALLBACK_SUCCESS
        ) {
            revert CallbackFailed();
        }

        // Check repayment
        if (address(this).balance < initialBalance) {
            revert RepayFailed();
        }

        emit LoanRepayed(address(receiver), amount);
        return true;
    }

    // Allow the pool to receive ETH
    receive() external payable {}
}
