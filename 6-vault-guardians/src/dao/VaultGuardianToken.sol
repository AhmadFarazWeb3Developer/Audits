// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// e used for avoiding approval from owner, just provide off chain signature to spender

import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//  q used to create vault guardian token to be held as a stack ?

contract VaultGuardianToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    constructor()
        ERC20("VaultGuardianToken", "VGT")
        ERC20Permit("VaultGuardianToken")
        Ownable(msg.sender)
    {}

    // The following functions are overrides required by Solidity.
    // q is this used for transfering tokens ?
    // q is approval needed ?
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    // q who will update this nonces ?
    // q is it prone to reply attack?

    // q we are implementing again this , its alreay in ERC20Permit.sol ?
    // q why are not using it directly ?
    function nonces(
        address ownerOfNonce
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(ownerOfNonce);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
