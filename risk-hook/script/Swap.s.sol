
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {PoolManager} from "v4-core/PoolManager.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "v4-core/test/PoolModifyLiquidityTest.sol";
import {PoolDonateTest} from "v4-core/test/PoolDonateTest.sol";
import {PoolTakeTest} from "v4-core/test/PoolTakeTest.sol";
import {PoolClaimsTest} from "v4-core/test/PoolClaimsTest.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {HookMiner} from "./HookMiner.sol";

import {TickMath} from "v4-core/libraries/TickMath.sol";

import { RiskManagerHook } from "../src/RiskManagerHook.sol";


import "forge-std/console.sol";

contract HookMiningScript is Script {

//    Deployed PoolManager at 0x74Bb711D032B5Df4F63dc04EA4422807D768aC08
//   Deployed PoolSwapTest at 0x9d8F28B52504112A8C89df9095ca3BF346286787
//   Deployed PoolModifyLiquidityTest at 0x5F1933923909C6a65a6769fA0d6F157857e33c48
//   Deployed PoolDonateTest at 0x3546914261a14D476671B02498420aDBbE7cA69A
//   Deployed PoolTakeTest at 0xA261F923654Eb93Ab6c35D285d58c8a01D42F792
//   Deployed PoolClaimsTest at 0x53a3A188943C94442D76396ba682b09a1e66517F

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_PRICE + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_PRICE - 1;


    PoolSwapTest swapRouter =
        PoolSwapTest(0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB);

    PoolModifyLiquidityTest modifyLiquidityRouter =
        PoolModifyLiquidityTest(0x2298870DB1Fa24F3F6cc1fa0B2760AB7c1803bC1);

    Currency token0;
    Currency token1;

    PoolKey key;

    function setUp() public {
        vm.startBroadcast();

        MockERC20 tokenA = MockERC20(0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7);
        MockERC20 tokenB = MockERC20(0xf21B5d9574d84eF4c253132691D76F62FEE4Daab);

        tokenA.approve(address(swapRouter), type(uint256).max);
        tokenB.approve(address(swapRouter), type(uint256).max);

        address owner = 0x000ef5F21dC574226A06C76AAE7060642A30eB74;

        address hookAddress = 0xA461b2227971866c6D35386bFf974903d247c088;


        key = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: 3000,
            tickSpacing: 120,
            hooks: IHooks(hookAddress)
        });

        // modifyLiquidityRouter.modifyLiquidity(
        //     key,
        //     IPoolManager.ModifyLiquidityParams({
        //         tickLower: -120,
        //         tickUpper: 120,
        //         liquidityDelta: 10000000000e18,
        //         salt: 0
        //     }),
        //     new bytes(0)
        // );

        // bytes memory data = abi.encode("swap((address,address,uint24,int24,address),(bool,int256,uint160),(bool,bool),bytes)", 
        //     key,
        //     IPoolManager.SwapParams({
        //         zeroForOne: false,
        //         amountSpecified: -1e17,
        //         sqrtPriceLimitX96: MAX_PRICE_LIMIT 
        //     }),
        //     PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
        //     abi.encode(owner, int256(1000000))
        // );

        // address(swapRouter).call(data);

        swapRouter.swap(key, IPoolManager.SwapParams({
            zeroForOne: true,
             amountSpecified: -1e17,
            sqrtPriceLimitX96: MIN_PRICE_LIMIT 
        }), PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}), abi.encode(owner, int256(1000000)));

        

        // IPoolManager(0x536527976E98E253B424a3655E695D144E343341).swap(
        //     PoolKey({
        //         currency0: Currency.wrap(address(0x15906379703940bc51a5881Ad1a5fc481Ebc8bB1)),
        //         currency1: Currency.wrap(address(0xbA397eFEF3914aB025F7f5706fADE61f240A9EbC)),
        //         fee: 3000,
        //         tickSpacing: 120,
        //         hooks: IHooks(0xBbd735DB53cE42a7423B0861864dAD6253588040)
        //     }),
        //     IPoolManager.SwapParams({
        //         zeroForOne: true,
        //         amountSpecified: int256(5e17),
        //         sqrtPriceLimitX96: MIN_PRICE_LIMIT 
        //     }),
        //     abi.encode(owner)
        // );



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