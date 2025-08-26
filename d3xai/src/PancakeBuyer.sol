
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PancakeBuyer {
    address targetContract;
    constructor(address target) {
        targetContract = target;
    }
    // 0xacfca76f
    function buy(address token1, address token2, address receiver, uint256 amount) public {
        (bool success, bytes memory result) = targetContract.delegatecall(
            abi.encodeWithSignature("buy(address,address,address,uint256)", token1, token2, receiver, amount)
        );
    }
}