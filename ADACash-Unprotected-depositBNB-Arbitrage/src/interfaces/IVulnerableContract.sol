// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVulnerableContract {
    function depositBNB() external payable;
    function claimRewards() external;
    function withdraw(uint256 amount) external;
    function deposits(address user) external view returns (uint256);
    function rewards(address user) external view returns (uint256);
    function totalDeposited() external view returns (uint256);
    function calculateReward(uint256 amount) external view returns (uint256);
}