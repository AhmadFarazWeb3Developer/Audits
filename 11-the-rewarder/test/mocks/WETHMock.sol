// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETHMock is ERC20 {
    constructor() ERC20("WETH Mock", "WETH") {
        _mint(address(this), 1000 ether);
    }
}
