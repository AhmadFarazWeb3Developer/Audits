// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract logicContract {
    // Note storage layout must be the same as contract A,
    // solidity knows the storage indexes not the name of vars

    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(uint256 _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract ProxyContract {
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(address _contract, uint256 _num) public payable {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
        require(success, "Delegation call failed");
    }
}
