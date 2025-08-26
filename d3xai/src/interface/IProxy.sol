// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IProxy {
    function exchange(address fromToken, address toToken, uint256 amount) external;
}