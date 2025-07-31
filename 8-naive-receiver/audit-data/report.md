# NaiveReceiverPool Security Audit Report

This document outlines security vulnerabilities identified in the `NaiveReceiverPool` smart contract, along with their descriptions, impacts, proofs of concept, and recommended mitigations. The issues are categorized by severity: High (H), Low (L), Informational (I), and Gas Optimization (G).

## Table of Contents

- [High Severity Issues](#high-severity-issues)
  - [H-1: Lack of Access Control on `UnstoppableVault::withdraw`](#h-1-lack-of-access-control-on-unstoppablevaultwithdraw)
  - [H-2: Meta-Transaction Signature Reuse - Forwarder Attack](#h-2-meta-transaction-signature-reuse---forwarder-attack)
  - [H-3: Underflow Leads to Potential DoS in `NaiveReceiver`](#h-3-underflow-leads-to-potential-dos-in-naivereceiver)
- [Low Severity Issues](#low-severity-issues)
  - [L-1: `NaiveReceiver::flashLoan` Not Following CEI](#l-1-naivereceiverflashloan-not-following-cei)
  - [L-2: `NaiveReceiver::flashLoan` Lacks Event Emission](#l-2-naivereceiverflashloan-lacks-event-emission)
- [Informational Issues](#informational-issues)
  - [I-1: `NaiveReceiver::withdraw` Lacks Condition Check on `totalDeposits` Withdrawal](#i-1-naivereceiverwithdraw-lacks-condition-check-on-totaldeposits-withdrawal)
  - [I-2: `NaiveReceiver::withdraw` Lacks Event Emission](#i-2-naivereceiverwithdraw-lacks-event-emission)
  - [I-3: `FlashLoanReceiver::pool` Should Be Immutable](#i-3-flashloanreceiverpool-should-be-immutable)
- [Gas Optimization Issues](#gas-optimization-issues)
  - [G-1: `flashLoanReceiver::_executeActionDuringFlashLoan` Not Used Anywhere](#g-1-flashloanreceiver_executeactionduringflashloan-not-used-anywhere)

## High Severity Issues

### H-1: Lack of Access Control on `UnstoppableVault::withdraw`

**Description**: The `NaiveReceiverPool` protocol provides flash loans to `FlashLoanReceiver`. When `FlashLoanReceiver` takes a flash loan via the `flashLoan` function, it returns a fee as profit to `NaiveReceiver`. The `withdraw` function allows `NaiveReceiver` to withdraw its profit or `totalDeposits`. However, the function lacks access control, enabling anyone to call `withdraw` and steal funds.

```javascript
function withdraw(uint256 amount, address payable receiver) external {
	deposits[_msgSender()] -= amount;
	totalDeposits -= amount;
	weth.transfer(receiver, amount);
}
```

**Impact**: Anyone can withdraw all funds from `NaiveReceiverPool`, leading to potential theft.

**Proof of Concept**:

1. Anyone can deposit tokens.
2. `FlashLoanReceiver` takes a loan.
3. The fee is returned.
4. Anyone calls `withdraw`.
5. Funds are withdrawn.

**Proof of Code**:
Run the code in `NaiveReceiverPool.t.sol`:

```javascript
function testWithDraw() public {
	console2.log("pool balance before:", weth.balanceOf(address(naivePool)));
	naivePool.withdraw(naivePool.totalDeposits(), payable(address(feeStealer)));
	console2.log("fee stealer:", weth.balanceOf(feeStealer));
	console2.log("pool balance after:", weth.balanceOf(address(naivePool)));
}
```

**Recommended Mitigation**: Use the `Ownable` contract at deployment and create an `onlyOwner` modifier for the `withdraw` function to restrict access to the contract owner.

---

### H-2: Meta-Transaction Signature Reuse - Forwarder Attack

**Description**: The `BasicForwarder` implements `EIP712`, allowing off-chain signatures to be used by a relayer. A malicious actor can trick a legitimate user into signing a malicious signature, which the attacker can use to misuse the user’s funds and send them to `NaiveReceiverPool` as a fee for a `flashLoan`.

```javascript
function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
	if (initiator != address(this) || msg.sender != address(vault) || token != address(vault.asset()) || fee != 0) {
		revert UnexpectedFlashLoan();
	}
		
	ERC20(token).approve(address(vault), amount);
	return keccak256("IERC3156FlashBorrower.onFlashLoan");
}
```

**Impact**: The `UnstoppableMonitor` blocks itself from taking flash loans within the `end` period when the fee is zero.

**Proof of Concept**:

1. A user signs an off-chain signature.
2. A malicious user tricks the user into signing a `BasicForwarder.Request`.
3. The malicious user signs the signature for themselves.
4. The signature is used in `FlashLoanReceiver.onFlashLoan`.
5. All funds are burned to `NaiveReceiverPool` as a fee.

**Proof of Code**:
Run the code in `NaiveReceiverPool.t.sol`:

```javascript
function testDrainUserFunds() public {
	// 1. Using dummy key
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
```

**Recommended Mitigation**:

```diff
```

---

### H-3: Underflow Leads to Potential DoS in `NaiveReceiver`

**Description**: At deployment, `NaiveReceiverPool` does not require initial funds. When a user attempts a flash loan exceeding the available deposit amount, the transaction reverts without proper error handling.

```javascript
function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
	if (token != address(weth)) revert UnsupportedCurrency();
	weth.transfer(address(receiver), amount);

	totalDeposits -= amount;

	if (receiver.onFlashLoan(msg.sender, address(weth), amount, FIXED_FEE, data) != CALLBACK_SUCCESS) {
		revert CallbackFailed();
	}

	uint256 amountWithFee = amount + FIXED_FEE;
	weth.transferFrom(address(receiver), address(this), amountWithFee);
	totalDeposits += amountWithFee;
	deposits[feeReceiver] += FIXED_FEE;

	return true;
}
```

**Impact**: The revert causes a denial-of-service (DoS) condition, confusing users attempting flash loans. In older Solidity versions, this could lead to an underflow of funds.

**Proof of Concept**:

1. No funds are in the pool.
2. The transaction always reverts.
3. This causes a DoS condition.

**Recommended Mitigation**:

1. Require a minimum deposit at deployment to ensure flash loans are available.
2. Add a `require` statement to check liquidity before calculations.

```diff
function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
	if (token != address(weth)) revert UnsupportedCurrency();
	weth.transfer(address(receiver), amount);

+   if (amount > totalDeposits) revert NotEnoughLiquidity();
	totalDeposits -= amount;

	if (receiver.onFlashLoan(msg.sender, address(weth), amount, FIXED_FEE, data) != CALLBACK_SUCCESS) {
		revert CallbackFailed();
	}

	uint256 amountWithFee = amount + FIXED_FEE;
	weth.transferFrom(address(receiver), address(this), amountWithFee);
	totalDeposits += amountWithFee;
	deposits[feeReceiver] += FIXED_FEE;

	return true;
}

+ error NotEnoughLiquidity();
```

## Low Severity Issues

### L-1: `NaiveReceiver::flashLoan` Not Following CEI

**Description**: The `flashLoan` function does not follow the Checks-Effects-Interactions (CEI) pattern. While not currently reentrant, future upgrades could introduce high-severity vulnerabilities, potentially leading to loss of funds.

**Impact**: Skipping CEI introduces risks for future upgrades or code extensions.

**Recommended Mitigation**:

```diff
function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
	if (token != address(weth)) revert UnsupportedCurrency();

-   weth.transfer(address(receiver), amount);
-   totalDeposits -= amount;
+   weth.transfer(address(receiver), amount); // Interaction
+   totalDeposits -= amount;                 // Effect

	if (receiver.onFlashLoan(msg.sender, address(weth), amount, FIXED_FEE, data) != CALLBACK_SUCCESS) {
		revert CallbackFailed();
	}

	uint256 amountWithFee = amount + FIXED_FEE;
	weth.transferFrom(address(receiver), address(this), amountWithFee);
	totalDeposits += amountWithFee;
	deposits[feeReceiver] += FIXED_FEE;

	return true;
}
```

---

### L-2: `NaiveReceiver::flashLoan` Lacks Event Emission

**Description**: The `flashLoan` function does not emit events, which is crucial for protocol accounting, monitoring, and integration with subgraph/indexer tools.

**Impact**: The lack of events results in no on-chain traceability of collected fees, reducing transparency for monitoring and integrations.

**Recommended Mitigation**:

```diff
function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
	if (token != address(weth)) revert UnsupportedCurrency();
	weth.transfer(address(receiver), amount);

	totalDeposits -= amount;

	if (receiver.onFlashLoan(msg.sender, address(weth), amount, FIXED_FEE, data) != CALLBACK_SUCCESS) {
		revert CallbackFailed();
	}

	uint256 amountWithFee = amount + FIXED_FEE;
	weth.transferFrom(address(receiver), address(this), amountWithFee);
	totalDeposits += amountWithFee;
	deposits[feeReceiver] += FIXED_FEE;

+   emit FlashLoanRepaid(address(receiver), amountWithFee);
+   emit FlashLoanFeeCollected(feeReceiver, FIXED_FEE);

	return true;
}

+ event FlashLoanRepaid(address indexed receiver, uint256 amountWithFee);
+ event FlashLoanFeeCollected(address indexed feeReceiver, uint256 feeAmount);
```

## Informational Issues

### I-1: `NaiveReceiver::withdraw` Lacks Condition Check on `totalDeposits` Withdrawal

**Description**: The `withdraw` function does not verify whether the withdrawal amount exceeds `totalDeposits`, potentially allowing invalid withdrawals.

---

### I-2: `NaiveReceiver::withdraw` Lacks Event Emission

**Description**: The `withdraw` function does not emit events, reducing transparency and traceability for monitoring and accounting purposes.

---

### I-3: `FlashLoanReceiver::pool` Should Be Immutable

**Description**: The `pool` variable in `FlashLoanReceiver` is not marked as `immutable`, despite being set only once during deployment. Marking it as `immutable` would optimize gas costs and improve code clarity.

## Gas Optimization Issues

### G-1: `flashLoanReceiver::_executeActionDuringFlashLoan` Not Used Anywhere

**Description**: The `_executeActionDuringFlashLoan` function in `FlashLoanReceiver` is defined but not used anywhere in the codebase, leading to unnecessary code bloat.
