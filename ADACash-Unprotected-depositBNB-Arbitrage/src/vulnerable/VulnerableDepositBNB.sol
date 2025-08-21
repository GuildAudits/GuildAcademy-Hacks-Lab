// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC20.sol";
import "../interfaces/IPancakeRouter.sol";

contract VulnerableDepositBNB {
    IERC20 public adaCash;
    IPancakeRouter public router;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public rewards;
    
    uint256 public totalDeposited;
    uint256 public rewardMultiplier = 2; // 2x rewards vulnerability
    
    event Deposit(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    
    constructor(address _adaCash, address _router) {
        adaCash = IERC20(_adaCash);
        router = IPancakeRouter(_router);
    }
    
    // VULNERABILITY: Uses contract balance instead of msg.value
    function depositBNB() external payable {
        uint256 amount = address(this).balance; // VULNERABLE: Should use msg.value
        
        deposits[msg.sender] += amount;
        totalDeposited += amount;
        
        // VULNERABILITY: Immediate reward calculation
        uint256 reward = calculateReward(amount);
        rewards[msg.sender] += reward;
        
        emit Deposit(msg.sender, amount);
    }
    
    // VULNERABILITY: No access control or time lock
    function calculateReward(uint256 amount) public view returns (uint256) {
        if (totalDeposited == 0) return 0;
        // Vulnerable to manipulation via direct transfers
        return (amount * rewardMultiplier * adaCash.balanceOf(address(this))) / totalDeposited;
    }
    
    // VULNERABILITY: No reentrancy protection
    function claimRewards() external {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards");
        
        rewards[msg.sender] = 0; // State change after external call vulnerability
        
        // External call without reentrancy guard
        adaCash.transfer(msg.sender, reward);
        
        emit RewardClaimed(msg.sender, reward);
    }
    
    // VULNERABILITY: Allows immediate withdrawal
    function withdraw(uint256 amount) external {
        require(deposits[msg.sender] >= amount, "Insufficient deposit");
        
        deposits[msg.sender] -= amount;
        totalDeposited -= amount;
        
        // Direct transfer without checks
        payable(msg.sender).transfer(amount);
    }
    
    // ADDED: Receive function to accept ETH transfers
    receive() external payable {}
    fallback() external payable {}
}
