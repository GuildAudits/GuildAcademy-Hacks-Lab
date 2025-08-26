// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVulnerableProxy {
    function deposit(address _userAddress, uint256 _wantAmt) external;
}
