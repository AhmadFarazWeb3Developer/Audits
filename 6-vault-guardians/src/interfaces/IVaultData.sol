// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// e used for distribute the user assest accross platforms

// q can user directly invest without hiring guradian ?
// q can gurdian steal money ?
// q who can contribute to the DAO ?
// is there any way to avoid malicious guardian or user enter the vault ?

interface IVaultData {
    /**
     * @notice The ratio of vault's underlying asset tokens to invest is set by the vault guardian and is stored in this struct
     * @notice holdAllocation is the ratio of tokens to hold in the vault. This is not invested in Uniswap v2 or Aave v3
     * @notice uniswapAllocation is the ratio of tokens to add as liquidity in Uniswap v2
     * @notice aaveAllocation is the ratio of tokens to provide as lending amount in Aave v3
     */
    struct AllocationData {
        uint256 holdAllocation; // hodl
        uint256 uniswapAllocation; // Simmilar to T-Swap
        uint256 aaveAllocation; // Similar to Thunder Loan
    }
}
