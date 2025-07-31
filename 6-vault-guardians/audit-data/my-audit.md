### [H-1] Malicious users can sweep the ERC funds from any user without the permission of the owner

**Description:** `VaultGuardians::sweepErc20s`  function is intended to recover stray ERC20 tokens (e.g., dust amounts) accidentally left in the contract, like when some of Weth 1.1 tokens are stuck in contract , so the owner of the contract can any time clean the contract. However, this function lacks access control, meaning any user can call it at any time.

**Impact:** There is no protection on `VaultGuardians::sweepErc20s` funtion and publicly accessible, which is used to recover stray ERC20s from any contract,so any malicious user can call it to sweep all tokens from the contract and transfer them to the owner's address, without the owner's permission or intent. Although the tokens are transferred to the owner's address and not stolen, this still poses significant risks:

1. Unexpected fund movement out of the contract
2. Interruption of protocol logic due to premature asset removal
3. Damage to trust and operational integrity

Proof of Concept:

```javascript
   function sweepErc20s(IERC20 asset) external {
        uint256 amount = asset.balanceOf(address(this));
        emit VaultGuardians__SweptTokens(address(asset));
        asset.safeTransfer(owner(), amount);
    }
```

**Proof of Concept:**

1. A user performs a swap or deposit operation, leaving a token residue in the vault contract.
2. Any external caller (malicious or accidental) calls sweepErc20s.
3. Tokens are sent to the owner, potentially affecting protocol operations or accounting logic.

<details>
<summary> Proof of Code </summary>
Refer to `VaultGuardians.t.sol` in `vault-guardians/test/unit/concrete/VaultGuardians.t.sol`

```javascript
  function testSweepErc20s() public {
        ERC20Mock mock = new ERC20Mock();
        ERC20Mock mock = new ERC20Mock();

        mock.mint(mintAmount, msg.sender);

        console2.log(mock.balanceOf(address(msg.sender)));

        vm.prank(msg.sender);
        mock.transfer(address(vaultGuardians), mintAmount);
        console2.log(mock.balanceOf(address(vaultGuardians)));
        console2.log(mock.balanceOf(address(msg.sender)));

        vm.prank(attacker);
        vaultGuardians.sweepErc20s(mock);

        console2.log(mock.balanceOf(address(vaultGuardians)));

        console2.log(
            "Sytem owner balance ",
            mock.balanceOf(vaultGuardians.owner())
        );
    }
```

</details>

**Recommended Mitigation:** create an `onlyOwner` modifer which apply on the function which is used to allow the protocol onwer to sweep the valults anytime

```diff

- function sweepErc20s(IERC20 asset) external {
+ function sweepErc20s(IERC20 asset) external onlyOwner {
        uint256 amount = asset.balanceOf(address(this));
        emit VaultGuardians__SweptTokens(address(asset));
        asset.safeTransfer(owner(), amount);
    }

```

### [M-1] Incorrect setting of voting period and delay in `VaultGuardianGovernor` contract

**Description:** In `VaultGuardianGovernor::votingDelay` and `VaultGuardianGovernor::votingPeriod`, the intended return is `1 days` and `7 days`, which normally seems okay, but actually, it returns the number of seconds, `1 days == 86400` and `7 days == 604800`. On-chain data works differently, meaning that if we take an average block time of `12 seconds`, this is a wrong calculation. The voting will end later than expected.

`Calulation :`

7200  blocks *12s = 86400 seconds =  1 day
</br>
50400 blocks* 12s = 604800 seconds = 7 days

Incorrect voting period and delay will be far off what the protocol intended, which could potentially affect the intended governance mechanics.

**Impact:** If `votingDelay` returns `86400`, and `votingPeriod` returns `604800`, the governance delay and voting duration will be much longer than intended.

**Recommended Mitigation:**

```diff
    function votingDelay() public pure override returns (uint256) {
-        return 1 days;
+        return 7200;
    }

    function votingPeriod() public pure override returns (uint256) {
-        return 7 days;
+        return 50400;
    }

```

### [L-1] Incorrect vault `vaultName` and `vaultSymbol` in `VaultGuardiansBase::becomeGuardian`, Abstracting `AStaticTokenData`

**Description:** While creating new vaults in the `VaultGuardianBase::becomeTokenGuardian` function,`vaultName`  and `vaultSymbols` are set incorrectly when the token is equal to `address(token) == address(i_tokenTwo)`.Consider modifying the function as follows , to avoid errors in off-chain reading these values to identify vaults.

```diff
else if (address(token) == address(i_tokenTwo)) {
    tokenVault =
    new VaultShares(IVaultShares.ConstructorData({
        asset: token,
-       vaultName: TOKEN_ONE_VAULT_NAME,
+       vaultName: TOKEN_TWO_VAULT_NAME,
-       vaultSymbol: TOKEN_ONE_VAULT_SYMBOL,
+       vaultSymbol: TOKEN_TWO_VAULT_SYMBOL,
        guardian: msg.sender,
        allocationData: allocationData,
        aavePool: i_aavePool,
        uniswapRouter: i_uniswapV2Router,
        guardianAndDaoCut: s_guardianAndDaoCut,
        vaultGuardian: address(this),
        weth: address(i_weth),
        usdc: address(i_tokenOne)
    }));
```

### [L-2] Unassigned return value when divesting AAVE funds in `AaveAdapter::_aaveDivest` function

**Description:** The `AaveAdapter::_aaveDivest` function is intended to return the amount of assets returned by Aave`IPool` interface after calling its withdraw function. However, the code never assigns a value to the named return variable `amountOfAssetReturned`. As a result, it will always return zero.

While this return value is not being used anywhere in the code, it may cause problems in future changes. Therefore, update the `_aaveDivest` function as follows:

```diff
   function _aaveDivest(IERC20 token, uint256 amount) internal returns (uint256 amountOfAssetReturned) {
-       i_aavePool.withdraw({
+       amountOfAssetReturned = i_aavePool.withdraw({
            asset: address(token),
            amount: amount,
            to: address(this)
        });
+       return amountOfAssetReturned;
}
```

### [L-3]  `VaultGuardians::updateGuardianAndDaoCut` emitting incorrect event instead of `VaultGuardians__UpdatedFee`

**Description:**  The `VaultGuardians::updateGuardianAndDaoCut` function is emitting an irrelevant event, `VaultGuardians__UpdatedStakePrice`, which is unrelated to the function's purpose of updating the guardian and DAO cut. This event is intended for stake price updates, and its emission in this context can lead to confusion and negatively impact the user experience.

The Recommended `Mitigation :`

```diff
   function updateGuardianAndDaoCut(uint256 newCut) external onlyOwner {
+        uint256 oldGuardianAndDaoCut = s_guardianAndDaoCut;
         s_guardianAndDaoCut = newCut;
-        emit VaultGuardians__UpdatedStakePrice(s_guardianAndDaoCut, newCut);
+        emit VaultGuardians__UpdatedFee(oldGuardianAndDaoCut,newCut); 
    }

```

### [L-4]  `VaultGuardians::updateGuardianStakePrice` emits event with incorrect stake price values

**Description:**  In the `VaultGuardians::updateGuardianStakePrice` function, the event `VaultGuardians__UpdatedStakePrice` is incorrectly emitting the new stake price twice instead of including the old stake price for comparison, which can mislead users and negatively impact the user experience.

The Recommended `Mitigation :`

```diff
   function updateGuardianStakePrice( uint256 newStakePrice) external onlyOwner {
+       uint256 oldStakePrice = s_guardianStakePrice;
        s_guardianStakePrice = newStakePrice;
-       emit VaultGuardians__UpdatedStakePrice(s_guardianStakePrice, newStakePrice);
+       emit VaultGuardians__UpdatedStakePrice(oldStakePrice, newStakePrice);
    }

```
