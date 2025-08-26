// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProxy} from "src/interface/IProxy.sol";
contract ProxyBuyerHelper {
    // 0xe09618e9
    function buy(address proxy, address token1, address token2, address receiver, uint256 amount) public {
        IERC20 usdt = IERC20(token1);
        IERC20 d3xat = IERC20(token2);
        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.approve(proxy, amount);

        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;

        IProxy(proxy).exchange(token1, token2, amount);
        uint256 bal = d3xat.balanceOf(address(this));
        d3xat.transfer(receiver, bal);
    }
}