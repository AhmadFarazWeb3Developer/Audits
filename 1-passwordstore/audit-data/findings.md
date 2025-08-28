### [H-1] Variable stored in storage on-chain are visiable to anyone, no matter the solidity keyword meaning the password is not actually private

## Likelihood & impact

- Impact: HIGH
- Likelihood: HIGH
- Severity: HIGH

**Description:** All data stored onchain is visiable to anyone, and can be rad direcltuy from the blockchain. The `PasswordStore::s_password` variable is intended to be private variable and only accessed through the `PasswordStore::getPassword` function, which is intended to be only called by the owner of the contract.

We show one such method of reading any data off chain below

**Impact:** Anyone can read the private password, severity breaking the functionality of the protocol.

**Proof of Concept:**(Proof of Code)

The below test case shows how anyone can read the password directly from the blockchain.

1. Create a locally running chain

```bash
make anvil
```

```
cast storage 0x5FbDB2315678afecb367f032d93F642f64180aa3 1 --rpc-url http://127.0.0.1:8545
```

output:

```
0x6d7950617373776f726400000000000000000000000000000000000000000014
```

```
cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
```

get the output:

```
myPassword
```

**Recommended Mitigation:** Due to this, the overall architecture of the contract should be rethought. One could encrypt the password off-chain, and then store the encrypted password on-chain. This would require the user to remember another password off-chain to decrypt the password. However, you'd also likely remove the view functions are you would'nt want user to accidentlly send a transaction with the password that decrypts your password.

### [H-2] `PasswordStore::setPassword` has no access control, meaning a non-owner could change the password

## Likelihood & impact

- Impact: HIGH
- Likelihood: HIGH
- Severity: HIGH

**Description:** The `PasswordStore::setPassword` function is set to be `external` function, however, the natspec of the function and overall purpose of the contract is that `This function allows only owner to set a new password.`

```javascript
    function setPassword(string memory newPassword) external {
@>  //@audit - There is no access control    
    s_password = newPassword;
        emit SetNewPassword();
    }
```

**Impact:** Anyone can set/change the password of the contract, severly breaking the contract intended functionality.

**Proof of Concept:** Add the following to the `PasswordStore.t.sol` test file.
<details>

```javascript
   function(){
    // testcase body
   }


```

paste you test code function here...
</details>

**Recommended Migitation**
