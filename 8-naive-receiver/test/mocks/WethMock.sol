// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WethMock is Test, ERC20 {
    constructor() payable ERC20("WETH MOCK", "WETH") {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }
    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}
