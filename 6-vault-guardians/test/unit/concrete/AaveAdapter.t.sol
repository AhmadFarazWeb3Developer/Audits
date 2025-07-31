pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {AaveAdapter} from "../../../src/protocol/investableUniverseAdapters/AaveAdapter.sol";
import {AavePoolMock} from "../../mocks/AavePoolMock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AaveAdapterTest is Test {
    AaveAdapter public aaveAdapter;
    AavePoolMock public aavePoolMock;
    ERC20Mock public weth;
    ERC20Mock public aToken;

    uint256 constant AMOUNT = 100 ether;

    function setUp() public {
        // Deploy mocks
        weth = new ERC20Mock();
        aToken = new ERC20Mock();
        aavePoolMock = new AavePoolMock();

        // Link aToken to asset
        aavePoolMock.updateAtokenAddress(address(weth), address(aToken));

        // Deploy adapter
        aaveAdapter = new AaveAdapter(address(aavePoolMock));

        // Mint WETH to the test contract and transfer to adapter
        weth.mint(AMOUNT, address(this));
        weth.transfer(address(aaveAdapter), AMOUNT); // ✅ Give adapter the WETH to invest

        // Adapter needs to approve AavePoolMock for WETH in actual _aaveInvest logic
        // This will happen inside the invest function

        // Mint aTokens to adapter to allow divest (simulate yield or returned principal)
        aToken.mint(AMOUNT, address(aaveAdapter));

        // Mint WETH to AavePoolMock to simulate withdrawal
        weth.mint(AMOUNT, address(aavePoolMock));
    }

    function testInvest() public {
        aaveAdapter._aaveInvest(IERC20(address(weth)), AMOUNT);
    }

    function testDeInvest() public {
        // Assume already invested
        aaveAdapter._aaveInvest(IERC20(address(weth)), AMOUNT);

        uint256 returnedAmount = aaveAdapter._aaveDivest(
            IERC20(address(weth)),
            AMOUNT
        );

        console2.log("Returned:", returnedAmount);
        assertEq(returnedAmount, AMOUNT);
    }
}
