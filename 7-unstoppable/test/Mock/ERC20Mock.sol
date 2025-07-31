// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("ERC20 MOCK", "ECM") {}

    function mint(address _address, uint256 _amount) public {
        _mint(_address, _amount);
    }
}
