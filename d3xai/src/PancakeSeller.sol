// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IPancakeRouter} from "src/interface/IPancakeRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PancakeSeller {
    address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // 0x83b95948
    function sell(address tokenOut, address tokenIn, address receiver) public {
        IERC20 d3xat = IERC20(tokenIn);
        IERC20 usdt = IERC20(tokenOut);
        uint256 d3Bal = d3xat.balanceOf(address(this));
        d3xat.approve(PANCAKE_ROUTER, d3Bal);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        IPancakeRouter(payable(PANCAKE_ROUTER)).swapExactTokensForTokensSupportingFeeOnTransferTokens(d3Bal, 0, path, address(this), block.timestamp);
        uint256 bal = usdt.balanceOf(address(this));
        usdt.transfer(receiver, bal);
    }
}