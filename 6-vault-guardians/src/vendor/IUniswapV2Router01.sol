// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// A subset of the UniswapV2Router01 interface
// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol

// Repsonsible for interacting with Pools 
interface IUniswapV2Router01 {
    // We've made these view instead of pure to make testing easier

    // e Returns the address of the Uniswap V2 Factory contract that creates and manages trading pairs
    function factory() external view returns (address);

    //  e Returns the address of the Wrapped ETH (WETH) token, used for ETH-related operations
    function WETH() external view returns (address);

    // e adds liquidity to a trading pair
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    // e removes liquidity to a trading pair
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint256 liquidity,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline,
    //     bool approveMax,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external returns (uint256 amountA, uint256 amountB);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
