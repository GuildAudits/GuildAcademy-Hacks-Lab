// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ProxyBuyer {
    address targetContract;
    constructor(address target) {
        targetContract = target;
    }
    // 0xe09618e9
    function buy(address proxy, address token1, address token2, address receiver, uint256 amount) public {
        (bool success, bytes memory result) = targetContract.delegatecall(
            abi.encodeWithSignature("buy(address,address,address,address,uint256)", proxy, token1, token2, receiver, amount)
        );
    }
}
