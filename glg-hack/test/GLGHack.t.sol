// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

interface IMintContract {
    function recoverToken(address token, address toAddr, uint256 amt) external;
    function owner() external view returns (address);
}

contract GLGExploitTest is Test {
    address constant MINT_CONTRACT = 0x0Ba0D250fdDb0580Afdd6BF278B54EfA76861420;
    address constant GLG_TOKEN = 0x4065Db0C9eb7d8F7BbF97763daeA183b771eBd4C;
    address constant ATTACKER = 0xC0EdcDdd6d5417c22467e3d5642Efa1820E454f8;
    uint256 constant STOLEN_AMOUNT = 8520389000000000000000000;
    
    function testSafeExploitReplay() public {
        console.log("=== SAFE EXPLOIT REPLAY ===");
        console.log("Block:", block.number);
        console.log("Attacker:", ATTACKER);
        
        // Check mint contract owner safely
        address mintOwner = getMintOwner();
        console.log("Mint owner:", mintOwner);
        console.log("Attacker is owner:", mintOwner == ATTACKER);
        
        // Check balances using low-level calls to avoid reverts
        uint256 mintBalance = getBalance(GLG_TOKEN, MINT_CONTRACT);
        uint256 attackerBalance = getBalance(GLG_TOKEN, ATTACKER);
        
        console.log("Mint contract GLG:", mintBalance / 1e18, "GLG");
        console.log("Attacker GLG:", attackerBalance / 1e18, "GLG");
        console.log("Attack amount:", STOLEN_AMOUNT / 1e18, "GLG");
        
        // Analyze the situation
        if (mintBalance < STOLEN_AMOUNT) {
            console.log("Mint doesn't have enough GLG - function must have a bug!");
        } else {
            console.log("Mint has sufficient GLG");
        }
        
        if (mintOwner == ATTACKER) {
            console.log("Attacker is owner - access control breach");
        } else {
            console.log("Attacker is NOT owner - different vulnerability");
        }
    }
    
    function testTransactionAnalysis() public {
        console.log("=== TRANSACTION ANALYSIS ===");
        
        // Let's analyze what actually happened in the transaction
        console.log("Transaction: 0x0e775318e1bbe249ad913ebad871bda105374b9a31b92b2145608ba110243e84");
        console.log("Function: recoverToken(GLGToken, Attacker, 8.5M GLG)");
        
        // The key question: How did this succeed?
        address mintOwner = getMintOwner();
        
        if (mintOwner == ATTACKER) {
            console.log("Answer: Attacker temporarily became owner");
        } else {
            console.log("Answer: recoverToken function has a critical bug");
            console.log("Possible bugs:");
            console.log("1. Transfers from token contract balance instead of mint balance");
            console.log("2. No proper balance validation");
            console.log("3. Reentrancy vulnerability");
        }
    }
    
    function testMintContractExamination() public view {
        console.log("=== MINT CONTRACT EXAMINATION ===");
        
        // Check if mint contract exists and is functional
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(MINT_CONTRACT)
        }
        console.log("Mint contract code size:", codeSize, "bytes");
        
        // Try to read owner with low-level call
        (bool success, bytes memory data) = MINT_CONTRACT.staticcall(
            abi.encodeWithSignature("owner()")
        );
        
        if (success && data.length == 32) {
            address owner = abi.decode(data, (address));
            console.log("Current owner:", owner);
        } else {
            console.log("Failed to read owner");
        }
    }
    
    // Helper functions to avoid reverts
    function getBalance(address token, address account) internal returns (uint256) {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("balanceOf(address)", account)
        );
        if (success && data.length == 32) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }
    
    function getMintOwner() internal returns (address) {
        (bool success, bytes memory data) = MINT_CONTRACT.staticcall(
            abi.encodeWithSignature("owner()")
        );
        if (success && data.length == 32) {
            return abi.decode(data, (address));
        }
        return address(0);
    }
}