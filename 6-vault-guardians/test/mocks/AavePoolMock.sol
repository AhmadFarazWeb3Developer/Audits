// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPool, DataTypes} from "../../src/vendor/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract AavePoolMock is IPool {
    mapping(address => address) public s_assetToAtoken;

    function updateAtokenAddress(address asset, address aToken) public {
        s_assetToAtoken[asset] = aToken;
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 /* referralCode */
    ) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);

        // Mint aTokens to the user
        address aToken = s_assetToAtoken[asset];
        require(aToken != address(0), "aToken not set");
        ERC20Mock(aToken).mint(amount, onBehalfOf);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function getReserveData(
        address asset
    ) external view returns (DataTypes.ReserveData memory) {
        DataTypes.ReserveConfigurationMap memory map = DataTypes
            .ReserveConfigurationMap({data: 0});
        return
            DataTypes.ReserveData({
                configuration: map,
                liquidityIndex: 0,
                currentLiquidityRate: 0,
                variableBorrowIndex: 0,
                currentVariableBorrowRate: 0,
                currentStableBorrowRate: 0,
                lastUpdateTimestamp: 0,
                id: 0,
                aTokenAddress: s_assetToAtoken[asset],
                stableDebtTokenAddress: address(0),
                variableDebtTokenAddress: address(0),
                interestRateStrategyAddress: address(0),
                accruedToTreasury: 0,
                unbacked: 0,
                isolationModeTotalDebt: 0
            });
    }

    // exclude from coverage
    function test() public {}
}
