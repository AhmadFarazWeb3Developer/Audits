// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {FlashLoanReceiver} from "./FlashLoanReceiver.sol";
import {Multicall} from "./Multicall.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract NaiveReceiverPool is Multicall, IERC3156FlashLender {
    // e 1 ETH or token fee
    uint256 private constant FIXED_FEE = 1e18; // not the cheapest flash loan

    bytes32 private constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    WETH public immutable weth; // WETH token

    address public immutable trustedForwarder;

    address public immutable feeReceiver;

    // e tracking deposits
    mapping(address => uint256) public deposits;

    // e number of deposits
    uint256 public totalDeposits;

    error RepayFailed();
    error UnsupportedCurrency();
    error CallbackFailed();

    // who ownes this contract ?
    // q lack of access control
    constructor(
        address _trustedForwarder,
        address payable _weth,
        address _feeReceiver
    ) payable {
        weth = WETH(_weth);
        trustedForwarder = _trustedForwarder;
        feeReceiver = _feeReceiver;
        // @audit-high  no check on msg.value , it cause underlflow in flashloan
        _deposit(msg.value);
    }

    function maxFlashLoan(address token) external view returns (uint256) {
        if (token == address(weth)) return weth.balanceOf(address(this));
        return 0;
    }
    // @audit-info useless params of unit
    function flashFee(address token, uint256) external view returns (uint256) {
        if (token != address(weth)) revert UnsupportedCurrency();
        return FIXED_FEE;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (token != address(weth)) revert UnsupportedCurrency();

        // Transfer WETH and handle control to receiver

        // @audit-low does it follow CEI ?

        weth.transfer(address(receiver), amount);

        // @audit-high underflow
        // amount > totalDeposits , underflow
        
        totalDeposits -= amount;

        if (
            receiver.onFlashLoan(
                msg.sender,
                address(weth),
                amount,
                FIXED_FEE,
                data
            ) != CALLBACK_SUCCESS
        ) {
            revert CallbackFailed();
        }

        uint256 amountWithFee = amount + FIXED_FEE;

        weth.transferFrom(address(receiver), address(this), amountWithFee);

        totalDeposits += amountWithFee;

        deposits[feeReceiver] += FIXED_FEE;

        return true;
    }

    // @audit-high any one can lack of access control
    function withdraw(uint256 amount, address payable receiver) external {
        // Reduce deposits
        deposits[_msgSender()] -= amount;
        totalDeposits -= amount;

        // Transfer ETH to designated receiver
        weth.transfer(receiver, amount);
    }

    function deposit() external payable {
        _deposit(msg.value);
    }

    // PRIVATE
    function _deposit(uint256 amount) private {
        weth.deposit{value: amount}();
        deposits[_msgSender()] += amount;
        totalDeposits += amount;
    }

    function _msgSender() internal view override returns (address) {
        if (msg.sender == trustedForwarder && msg.data.length >= 20) {
            return address(bytes20(msg.data[msg.data.length - 20:]));
        } else {
            return super._msgSender();
        }
    }
}
