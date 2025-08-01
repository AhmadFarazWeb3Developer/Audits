import {UtilsTest} from "./Utils.t.sol";
import {Test, console2} from "forge-std/Test.sol";

contract TrusterLenderPoolTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testDVTs() public view {
        token.balanceOf(address(trusterLenderPool));
    }

    function testStealAllPoolFunds() public {
        console2.log(
            "Pool balance before : ",
            token.balanceOf(address(trusterLenderPool))
        );
        console2.log(
            "Target balance before : ",
            token.balanceOf(target.attacker())
        );

        target.attack();
        console2.log(
            "Pool balance After : ",
            token.balanceOf(address(trusterLenderPool))
        );
        console2.log(
            "Target balance After : ",
            token.balanceOf(target.attacker())
        );
    }
}
