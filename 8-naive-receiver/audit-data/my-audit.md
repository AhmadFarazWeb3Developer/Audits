
### [H-1] Lack of Access Control on `UnstoppableVault::withdraw`

**Description:** The `NaiveReceiverPool` protocol is designed to provide flash loans to `FlashLoanReceiver`. When `FlashLoanReceiver` take the flash loan via `flashLoan` and provide the fee as profit back to the `NaiveReceiver`. At any time `NaiveReceiver` can withdraw his profil or `totalDeposits` via `withdraw` function. The potential issue lies here the any one can call the withdraw and steal the funds, becase the function lack the access control.

```javascript

```

**Impact:** Violating this condition renders the vault inoperable, preventing all users from obtaining flash loans. While the vault owner can adjust tokens and shares, the function remains susceptible to DoS attacks.

**Proof of Concept:**

*Normal User:*

1. Calls `flashLoan`.
2. The condition `convertToShares(totalSupply) != balanceBefore` is checked.
3. The `flashFee` is calculated.
4. The flash loan is granted.
5. The flash loan is recovered.

*Malicious User:*

1. Calls `ERC4626::deposit(uint256 assets, address receiver)`.
2. The condition `convertToShares(totalSupply) != balanceBefore` causes reverts for all users.

<details>

<summary> Proof of Code:</summary>

Run the code in `Vault.t.sol`:

```javascript
function testDoSFlashLoanByDirectTransfer() public {
    // 1. Attacker directly transfers 1 token to the vault
    vm.startPrank(attacker);
    token.mint(attacker, 1);
    token.transfer(address(vault), 1);
    vm.stopPrank();

    // 2. A legitimate user tries to take a flash loan
    vm.startPrank(address(this));
    token.mint(address(this), 20);
    token.approve(address(vault), 20);
    vault.deposit(20, address(this));

    vm.expectRevert();
    vault.flashLoan(IERC3156FlashBorrower(monitor), address(token), 10, "");
    vm.stopPrank();
}
```

</details>

**Recommended Mitigation:** Implement a `deposit` function in `UnstoppableVault` to allow users to deposit tokens, ensuring that the vault's shares are updated to match the number of tokens deposited.

### [H-2] `UnstoppableMonitor::onFlashLoan` Reverts on Zero Fee

**Description:** The `UnstoppableVault` protocol is designed to provide flash loans to `UnstoppableMonitor`, which can request loans before or after the `end` period. However, the `UnstoppableMonitor` contract restricts itself to non-zero fees, reverting with an `UnexpectedFlashLoan()` error even when eligible for a zero-fee flash loan.

```javascript
function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
    if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || fee != 0) {
        revert UnexpectedFlashLoan();
    }
        
    ERC20(token).approve(address(vault), amount);
    return keccak256("IERC3156FlashBorrower.onFlashLoan");
}
```

**Impact:** The `UnstoppableMonitor` blocks itself from taking flash loans within the `end` period when the fee is zero.

**Proof of Concept:**

1. Monitor initiates a flash loan.
2. Condition `block.timestamp < end && _amount < maxFlashLoan(token)` is met.
3. Fee is set to `0`.
4. `receiver.onFlashLoan(@params)` is called.
5. `UnstoppableMonitor` reverts due to the `fee != 0` check.

<details>
<summary> Proof of Code:</summary>

Run the code in `Vault.t.sol`:

```javascript
function testFlashLoan() public {
    vm.startPrank(address(monitor));
    vault.flashLoan(IERC3156FlashBorrower(monitor), address(token), 10, "");
    vm.stopPrank();
}
```

</details>

**Recommended Mitigation:** Remove the `fee != 0` check to allow zero-fee flash loans. Alternative logic can be implemented to manage this behavior.

```diff
function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
    if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || 
-   fee != 0
    ) {
        revert UnexpectedFlashLoan();
    }
        
    ERC20(token).approve(address(vault), amount);
    return keccak256("IERC3156FlashBorrower.onFlashLoan");
}
```

### [H-3] `UnstoppableVault` Fails to Recover Fees

**Description:** When `UnstoppableMonitor` takes a flash loan from `UnstoppableVault`, the `UnstoppableMonitor::onFlashLoan` function does not approve sufficient tokens for `UnstoppableVault` to recover both the loan amount and the fee, particularly after the `end` period.

```javascript
function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
    if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || fee != 0) {
        revert UnexpectedFlashLoan();
    }
        
@>   ERC20(token).approve(address(vault), amount);
     ERC20(token).approve(address(vault), amount);
    return keccak256("IERC3156FlashBorrower.onFlashLoan");
}
```

**Impact:** `UnstoppableVault` cannot recover its fee from `UnstoppableMonitor`, causing transactions to revert with an `ERC20InsufficientAllowance` error.

**Proof of Concept:**

Run the code in `Vault.t.sol`, and review `Utils.t.sol` for additional context:

```javascript
function testFlashLoan() public {
    vm.startPrank(address(monitor));
    vault.flashLoan(IERC3156FlashBorrower(monitor), address(token), 10, "");
    vm.stopPrank();
}
```

**Recommended Mitigation:** Update `UnstoppableMonitor::onFlashLoan` to approve `amount + fee` to allow `UnstoppableVault` to recover both the loan and the fee.

```diff
function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
    if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || fee != 0) {
        revert UnexpectedFlashLoan();
    }
        
-    ERC20(token).approve(address(vault), amount);
+    ERC20(token).approve(address(vault), amount + fee);
    return keccak256("IERC3156FlashBorrower.onFlashLoan");
}
```
