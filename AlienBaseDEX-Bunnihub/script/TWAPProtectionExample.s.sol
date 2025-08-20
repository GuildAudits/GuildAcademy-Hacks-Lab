// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

// Uniswap V3 Pool interface
interface IUniswapV3Pool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
    
    function observe(uint32[] calldata secondsAgos) external view returns (
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s
    );
}

// Simplified TWAP protection example
contract TWAPProtectionExample {
    uint256 public constant MAX_DEVIATION_BPS = 500; // 5% in basis points
    uint32 public constant TWAP_WINDOW = 3600; // 1 hour
    
    function getTWAP(address pool, uint32 window) public view returns (int24) {
        IUniswapV3Pool poolContract = IUniswapV3Pool(pool);
        
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = window;
        secondsAgos[1] = 0;
        
        (int56[] memory tickCumulatives, ) = poolContract.observe(secondsAgos);
        
        // Safe arithmetic to avoid overflow
        int56 tickCumulativeDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 avgTick = int24(tickCumulativeDelta / int56(uint56(window)));
        
        return avgTick;
    }
    
    function calculatePriceDeviation(int24 currentTick, int24 twapTick) public pure returns (uint256) {
        // Calculate price deviation in basis points
        int24 tickDifference = currentTick > twapTick ? currentTick - twapTick : twapTick - currentTick;
        
        // Convert tick difference to basis points (approximate)
        // Each tick represents roughly 0.01% price change
        return uint256(uint24(tickDifference)) * 100; // Convert to basis points
    }
    
    // Example of protected compound function
    function compoundWithTWAPProtection(address pool) external view returns (bool) {
        // Get current tick
        (, int24 currentTick, , , , , ) = IUniswapV3Pool(pool).slot0();
        
        // Get TWAP tick
        int24 twapTick = getTWAP(pool, TWAP_WINDOW);
        
        // Calculate deviation
        uint256 deviation = calculatePriceDeviation(currentTick, twapTick);
        
        console.log("Current Tick:", currentTick);
        console.log("TWAP Tick:", twapTick);
        console.log("Tick Difference:", currentTick > twapTick ? currentTick - twapTick : twapTick - currentTick);
        console.log("Price Deviation:", deviation, "basis points");
        console.log("Max Deviation:", MAX_DEVIATION_BPS, "basis points");
        
        // Check if deviation is acceptable
        bool isSafe = deviation <= MAX_DEVIATION_BPS;
        console.log("TWAP Check Passed:", isSafe);
        
        return isSafe;
    }
}

contract TWAPProtectionDemo is Script {
    address constant TARGET_POOL = 0xbF75A14a107145eF954079287870Bf87aCdd0a36;
    
    function run() external {
        // Fork Base mainnet
        vm.createSelectFork("base");
        
        console.log("=== TWAP Protection Demo ===");
        console.log("Pool Address:", TARGET_POOL);
        console.log("Network ID:", block.chainid);
        console.log("Block Number:", block.number);
        
        TWAPProtectionExample twapProtection = new TWAPProtectionExample();
        
        console.log("\n=== Testing TWAP Protection ===");
        
        // Test current price vs TWAP
        bool isSafe = twapProtection.compoundWithTWAPProtection(TARGET_POOL);
        
        console.log("\n=== TWAP Protection Analysis ===");
        console.log("TWAP Protection Status:", isSafe ? "SAFE" : "UNSAFE");
        
        if (isSafe) {
            console.log("Price deviation is within acceptable bounds");
            console.log("Compound operation would be allowed");
        } else {
            console.log("Price deviation exceeds maximum threshold");
            console.log("Compound operation would be blocked");
        }
        
        
        
        console.log("\n=== TWAP Protection Demo Complete ===");
    }
}
