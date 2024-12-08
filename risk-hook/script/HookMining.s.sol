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

import { IRiskManagerStylus, RiskManagerHook } from "../src/RiskManagerHook.sol";

import "forge-std/console.sol";

contract HookMiningScript is Script {


    PoolManager manager =
        PoolManager(0xc420C3A3F81f2A059fF56D45c0A82D1F9aF38dCc);
    PoolSwapTest swapRouter =
        PoolSwapTest(0x1649883be9b0d4D83092CDB430c42E6d5C1B7cAB);
    PoolModifyLiquidityTest modifyLiquidityRouter =
        PoolModifyLiquidityTest(0x2298870DB1Fa24F3F6cc1fa0B2760AB7c1803bC1);

    Currency token0;
    Currency token1;

    PoolKey key;

    function setUp() public {
        vm.startBroadcast();

        IRiskManagerStylus riskManager = IRiskManagerStylus(0x086CcAf62d35E15300f8719c950A90269F9d72C6);

        MockERC20 tokenA = MockERC20(0x313Adf3Fa3479F6Bf5aedBc7949EE5e1213F20B7);
        MockERC20 tokenB = MockERC20(0xf21B5d9574d84eF4c253132691D76F62FEE4Daab);
        address owner = 0x000ef5F21dC574226A06C76AAE7060642A30eB74;


        if (address(tokenA) > address(tokenB)) {
            (token0, token1) = (
                Currency.wrap(address(tokenB)),
                Currency.wrap(address(tokenA))
            );
        } else {
            (token0, token1) = (
                Currency.wrap(address(tokenA)),
                Currency.wrap(address(tokenB))
            );
        }

        tokenA.approve(address(modifyLiquidityRouter), type(uint256).max);
        tokenB.approve(address(modifyLiquidityRouter), type(uint256).max);
        tokenA.approve(address(swapRouter), type(uint256).max);
        tokenB.approve(address(swapRouter), type(uint256).max);

        tokenA.mint(msg.sender, 1000000000000000 * 10 ** 18);
        tokenB.mint(msg.sender, 1000000000000000 * 10 ** 18);

        // Mine for hook address
        vm.stopBroadcast();

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG);

        address CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(RiskManagerHook).creationCode,
            abi.encode(address(manager), address(riskManager))
        );

        vm.startBroadcast();
        RiskManagerHook hook = new RiskManagerHook{salt: salt}(manager, riskManager);

        console.log("Hook address:", address(hook));


        require(address(hook) == hookAddress, "hook address mismatch");

        key = PoolKey({
            currency0: token0,
            currency1: token1,
            fee: 3000,
            tickSpacing: 120,
            hooks: hook
        });

        // the second argument here is SQRT_PRICE_1_1
        manager.initialize(key, 79228162514264337593543950336);
        vm.stopBroadcast();
    }

    function run() public {
        vm.startBroadcast();
        modifyLiquidityRouter.modifyLiquidity(
            key,
            IPoolManager.ModifyLiquidityParams({
                tickLower: -120,
                tickUpper: 120,
                liquidityDelta: 10000e18,
                salt: 0
            }),
            new bytes(0)
        );
        vm.stopBroadcast();
    }
}