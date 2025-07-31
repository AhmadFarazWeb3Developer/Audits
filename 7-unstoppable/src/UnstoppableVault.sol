// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";
// @audit-info , solmate is no longer maintained

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib, ERC4626, ERC20} from "solmate/tokens/ERC4626.sol";

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC3156FlashBorrower, IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

/**
 * An ERC4626-compliant tokenized vault offering flashloans for a fee.
 * An owner can pause the contract and execute arbitrary changes.
 */

contract UnstoppableVault is
    IERC3156FlashLender,
    ReentrancyGuard,
    Owned,
    ERC4626,
    Pausable
{
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    uint256 public constant FEE_FACTOR = 0.05 ether;
    uint64 public constant GRACE_PERIOD = 30 days;

    // @audit-low ?
    uint64 public immutable end = uint64(block.timestamp) + GRACE_PERIOD;

    address public feeRecipient;

    error InvalidAmount(uint256 amount);
    error InvalidBalance();
    error CallbackFailed();
    error UnsupportedCurrency();

    event FeeRecipientUpdated(address indexed newFeeRecipient);

    constructor(
        ERC20 _token,
        address _owner,
        address _feeRecipient
    ) ERC4626(_token, "Too Damn Valuable Token", "tDVT") Owned(_owner) {
        // @audit-info, _feeRecipient must not be null address
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /**
     * @inheritdoc IERC3156FlashLender
     */

    // e checking the max flash loan can someone take out
    function maxFlashLoan(
        address _token
    ) public view nonReadReentrant returns (uint256) {
        if (address(asset) != _token) {
            return 0;
        }
        return totalAssets();
    }

    /**
     * @inheritdoc IERC3156FlashLender
     */

    function flashFee(
        address _token,
        uint256 _amount
    ) public view returns (uint256 fee) {
        if (address(asset) != _token) {
            // e if not loaning for same asset token , means USCD == USDC
            revert UnsupportedCurrency();
        }
        // @audit-low single miner can manipulate the time upto 15 seconds , can by pass the 0 fee , it happen only one time in
        //  each 30 days
        if (block.timestamp < end && _amount < maxFlashLoan(_token)) {
            return 0;
        } else {
            return _amount.mulWadUp(FEE_FACTOR);
        }
    }

    /**
     * @inheritdoc IERC3156FlashLender
     */

    // take flash loan
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address _token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (amount == 0) revert InvalidAmount(0); // fail early
        if (address(asset) != _token) revert UnsupportedCurrency(); // enforce ERC3156 requirement

        uint256 balanceBefore = totalAssets();

        // @audit-high-DOS,
        // Yes this rule be broken for always, making vault inactive permanetnly
        // if any one send token directly to the valut and vault didnt mint shares againts amount of
        //sent tokens then this condition will always fail

        // we are comparing it with the total supply

        if (convertToShares(totalSupply) != balanceBefore)
            revert InvalidBalance(); // enforce ERC4626 requirement

        // transfer tokens out + execute callback on receiver

        // q send USDC to Moniter ?

        // @audit Reentrancy ?
        ERC20(_token).safeTransfer(address(receiver), amount);

        // callback must return magic value, otherwise assume it failed
        uint256 fee = flashFee(_token, amount); // it will return fee

        if (
            receiver.onFlashLoan(
                msg.sender,
                address(asset),
                amount,
                fee,
                data
            ) != keccak256("IERC3156FlashBorrower.onFlashLoan")
        ) {
            revert CallbackFailed();
        }
        // pull amount + fee from receiver, then pay the fee to the recipient

        // @audit- high always fails because monitor is not giving enoguh approval, amount < amount + fee
        ERC20(_token).safeTransferFrom(
            address(receiver),
            address(this),
            amount + fee
        );

        ERC20(_token).safeTransfer(feeRecipient, fee);

        return true;
    }

    /**
     * @inheritdoc ERC4626
     */
    function totalAssets()
        public
        view
        override
        nonReadReentrant
        returns (uint256)
    {
        return asset.balanceOf(address(this));
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient != address(this)) {
            feeRecipient = _feeRecipient;
            emit FeeRecipientUpdated(_feeRecipient);
        }
    }

    // Allow owner to execute arbitrary changes when paused
    function execute(
        address target,
        bytes memory data
    ) external onlyOwner whenPaused {
        (bool success, ) = target.delegatecall(data);
        require(success);
    }

    // Allow owner pausing/unpausing this contract
    function setPause(bool flag) external onlyOwner {
        if (flag) _pause();
        else _unpause();
    }

    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
     * @inheritdoc ERC4626
     */

    // @audit-info, unused function
    function beforeWithdraw(
        uint256 assets,
        uint256 shares
    ) internal override nonReentrant {}

    /**
     * @inheritdoc ERC4626
     */
    // audit-info unused
    function afterDeposit(
        uint256 assets,
        uint256 shares
    ) internal override nonReentrant whenNotPaused {}
}
