// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IProxy} from "src/interface/IProxy.sol";
contract ProxySeller {
    // 0x82839fae
    function sell(address proxy, address fromToken, address toToken, uint256 amount, address receiver) public {
        IERC20 d3xat = IERC20(fromToken);
        IERC20 usdt = IERC20(toToken);
        uint256 d3Bal = d3xat.balanceOf(address(this));
        d3xat.approve(proxy, amount);
        IProxy(proxy).exchange(fromToken, toToken, amount);
        uint256 bal = usdt.balanceOf(address(this));
        usdt.transfer(receiver, bal);
    }
}
