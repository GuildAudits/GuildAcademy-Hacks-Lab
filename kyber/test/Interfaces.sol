// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC20.sol";

interface Interfaces {
    // AAVE V3 POOL
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    // IERC20

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);

    // KYBERSWAP
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24[2] ticksPrevious;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function swap(address recipient, int256 swapQty, bool isToken0, uint160 limitSqrtP, bytes calldata data)
        external
        returns (int256 deltaQty0, int256 deltaQty1);

    function tickDistance() external view returns (int24);
    function swapFeeUnits() external view returns (uint24);
    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

    function getPoolState()
        external
        view
        returns (uint160 sqrtP, int24 currentTick, int24 nearestCurrentTick, bool locked);

    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
}
