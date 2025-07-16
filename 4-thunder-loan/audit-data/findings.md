### [H-1] Erroneous `ThunderLoan::updateExchangeRate` in the `deposit` function causes protocol to think it has more fees than it really does, which blocks redemption and incorrectly sets the exchange rate

**Description:** In the ThunderLoan system, the `exchangeRate` is responsible for calculating the exchange rate between assestToken and underlying tokens. In a way, its responsible for keeping track record of how many fees to give to liquidity providers.

However, the `deposit` function, updates this rate, without collecting any fee! This update should be removed.

```javascript
   function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;

        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
        // @audit-high
@>      uint256 calculatedFee = getCalculatedFee(token, amount);
@>      assetToken.updateExchangeRate(calculatedFee);

        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }

```

**Impact:** There are several impacts of this bug.

1. The `redeem` function id blocked because the protocol thinks the owed tokens is more than it has.
2. Rewards are incorrectly calculated, leading to liquidity providers potentially getting way more or less than deserved.

**Proof of Concept:**

1. LP deposits
2. User takes out a flash loan.
3. It is now impossible for LP to redeem.

<details>
<summary>Proof of Code</summary>

Place the following into `ThunderLoanTest.t.sol`

```javascript
function testRedeemAfterLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee( tokenA, amountToBorrow );

        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT); // fee
        thunderLoan.flashloan( address(mockFlashLoanReceiver), tokenA, amountToBorrow, "" );
        vm.stopPrank();
    
        uint256 amountToRedeem = type(uint256).max;
        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, amountToRedeem);
    }

```

</details>

**Recommended Migitation:** Remove the incorrectly updated exchange rate lines from `deposit`.

```diff
   function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;

        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);
        
        // @audit-high
-      uint256 calculatedFee = getCalculatedFee(token, amount);
-      assetToken.updateExchangeRate(calculatedFee);

        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }
```
