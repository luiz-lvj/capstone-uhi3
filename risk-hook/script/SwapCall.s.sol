


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";



import "forge-std/console.sol";

contract HookMiningScript is Script {

    function setUp() public {
        vm.startBroadcast();


        address target = 0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB;

        




        vm.stopBroadcast();
    }

    function run() public {
        // modifyLiquidityRouter.modifyLiquidity(
        //     key,
        //     IPoolManager.ModifyLiquidityParams({
        //         tickLower: -120,
        //         tickUpper: 120,
        //         liquidityDelta: 10000e18,
        //         salt: 0
        //     }),
        //     new bytes(0)
        // );
    }
}