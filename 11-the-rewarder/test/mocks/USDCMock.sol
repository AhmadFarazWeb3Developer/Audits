// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCMock is ERC20 {
    constructor() ERC20("USDC Mock", "USDC") {
        _mint(address(this), 1000 ether);
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
