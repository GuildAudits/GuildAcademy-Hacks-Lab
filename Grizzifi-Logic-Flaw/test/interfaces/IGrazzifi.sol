// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGrazzifi {
    function collectHoney(uint256 _planId) external;
    function retrieveHoneyPot(uint256 _planId) external;
    function harvestHoney(
        uint256 _planId,
        uint256 _amount,
        address _referrer
    ) external;
    function startProject() external;
    function collectRefBonus() external;
}
