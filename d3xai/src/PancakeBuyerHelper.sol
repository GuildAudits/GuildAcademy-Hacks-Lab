
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IPancakeRouter} from "src/interface/IPancakeRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PancakeBuyerHelper {
    address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // 0xacfca76f
    function buy(address token1, address token2, address receiver, uint256 amount) public {
        IERC20 usdt = IERC20(token1);
        IERC20 d3xat = IERC20(token2);
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.approve(PANCAKE_ROUTER, amount);

        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;

        IPancakeRouter(payable(PANCAKE_ROUTER)).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
        uint256 bal = d3xat.balanceOf(address(this));
        d3xat.transfer(receiver, bal);
    }
}
