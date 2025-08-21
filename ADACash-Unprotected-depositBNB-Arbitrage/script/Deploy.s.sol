// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/vulnerable/VulnerableDepositBNB.sol";
import "../src/vulnerable/ADACashMock.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy ADACash mock
        ADACashMock adaCash = new ADACashMock();
        console.log("ADACash deployed at:", address(adaCash));
        
        // Deploy vulnerable contract
        VulnerableDepositBNB vulnerable = new VulnerableDepositBNB(
            address(adaCash),
            pancakeRouter
        );
        console.log("Vulnerable contract deployed at:", address(vulnerable));
        
        // Fund vulnerable contract with rewards
        adaCash.transfer(address(vulnerable), 100000 * 10**18);
        console.log("Funded vulnerable contract with 100,000 ADACash");
        
        vm.stopBroadcast();
    }
}