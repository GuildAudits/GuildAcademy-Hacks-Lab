// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAttackersContract {
    function create2() external;
    function create(uint256, address, address) external payable;
    function init(address) external payable;
    function owner() external view returns (address);
    function withdraw(address) external;
    function getList() external view returns (address[] memory);
}
