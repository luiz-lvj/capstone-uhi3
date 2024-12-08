// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {CurrencySettler} from "v4-periphery/lib/v4-core/test/utils/CurrencySettler.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {BeforeSwapDelta, toBeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";
import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";


interface IRiskManagerStylus {
    function init() external;

    function owner() external view returns (address);

    function addWhitelistedToken(address token, address price_oracle, address vol_oracle) external;

    function allowedSwap(address user, int256 max_vol, address token_in, int256 token_in_amount, address token_out, int256 token_out_amount) external view returns (bool);

    error NotOwner(address, address);

    error TokenAlreadyWhitelisted(address);

    error TokenNotWhitelisted(address);
}


contract RiskManagerHook is BaseHook {
	using CurrencySettler for Currency;

    error SwapNotAllowed(address user, int256 maxVol, address tokenIn, int256 tokenInAmount, address tokenOut, int256 tokenOutAmount);


    IRiskManagerStylus public riskManager;

    constructor(IPoolManager _poolManager, IRiskManagerStylus _riskManager) BaseHook(_poolManager) {
        riskManager = _riskManager;
    }


    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false, // Don't allow adding liquidity normally
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false, // Override how swaps are done
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false, // Allow beforeSwap to return a custom delta
                afterSwapReturnDelta: true,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }


    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, BalanceDelta delta, bytes calldata hookData)
        external
        override
        returns (bytes4, int128)
    {

        address tokenIn = swapParams.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
        address tokenOut = swapParams.zeroForOne ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);


        int256 tokenInAmount = swapParams.zeroForOne ? swapParams.amountSpecified : delta.amount1();
        int256 tokenOutAmount = swapParams.zeroForOne ? delta.amount0() : swapParams.amountSpecified;


        (address user, int256 maxVol) = abi.decode(hookData, (address, int256));


        if (!riskManager.allowedSwap(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount)) {
            revert SwapNotAllowed(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount);
        }

        return (BaseHook.afterSwap.selector, 0);
    }

}
