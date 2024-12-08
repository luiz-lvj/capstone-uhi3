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

import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";

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


    event SwapAllowed(address user, int256 maxVol, address tokenIn, int256 tokenInAmount, address tokenOut, int256 tokenOutAmount);

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
                beforeSwap: true, // Override how swaps are done
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: true, // Allow beforeSwap to return a custom delta
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }


    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, bytes calldata hookData)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        
        if (swapParams.amountSpecified < 0) {
        
            address tokenIn = swapParams.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
            address tokenOut = swapParams.zeroForOne ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);


            uint160 sqrtPriceLimitX96 = swapParams.sqrtPriceLimitX96;

            // calculate expected amount in and amount out
            int256 tokenInAmount = swapParams.zeroForOne 
                ? int256(uint256(swapParams.amountSpecified) * uint256(sqrtPriceLimitX96) / (1 << 96))
                : int256(uint256(swapParams.amountSpecified));

            int256 tokenOutAmount = swapParams.zeroForOne 
                ? int256(uint256(swapParams.amountSpecified))
                : int256(uint256(swapParams.amountSpecified) * uint256(sqrtPriceLimitX96) / (1 << 96));

            tokenInAmount = tokenInAmount < 0 ? -tokenInAmount : tokenInAmount;
            tokenOutAmount = tokenOutAmount < 0 ? -tokenOutAmount : tokenOutAmount;
        
            
            (address user, int256 maxVol) = abi.decode(hookData, (address, int256));

            if (!riskManager.allowedSwap(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount)) {
                // NoOp only works on exact-input swap
                    // take the input token so that v3-swap is skipped...
                Currency input = swapParams.zeroForOne ? key.currency0 : key.currency1;
                uint128 amountTaken = uint128(-int128(swapParams.amountSpecified));
                poolManager.mint(address(this), input.toId(), uint256(amountTaken));

                // to NoOp the exact input, we return the amount that's taken by the hook
                return (BaseHook.beforeSwap.selector, toBeforeSwapDelta(int128(amountTaken), 0), 0);
            } else{
                emit SwapAllowed(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount);
            }
        }
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }


    // function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, BalanceDelta delta, bytes calldata hookData)
    //     external
    //     override
    //     returns (bytes4, int128)
    // {

    //     address tokenIn = swapParams.zeroForOne ? Currency.unwrap(key.currency0) : Currency.unwrap(key.currency1);
    //     address tokenOut = swapParams.zeroForOne ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);


    //     int256 tokenInAmount = swapParams.zeroForOne ? swapParams.amountSpecified : delta.amount1();
    //     int256 tokenOutAmount = swapParams.zeroForOne ? delta.amount0() : swapParams.amountSpecified;

    //     tokenInAmount = tokenInAmount < 0 ? -tokenInAmount : tokenInAmount;
    //     tokenOutAmount = tokenOutAmount < 0 ? -tokenOutAmount : tokenOutAmount;


    //     (address user, int256 maxVol) = abi.decode(hookData, (address, int256));


    //     if (!riskManager.allowedSwap(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount)) {
    //         revert SwapNotAllowed(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount);
    //     }

    //     emit SwapAllowed(user, maxVol, tokenIn, tokenInAmount, tokenOut, tokenOutAmount);

    //     return (BaseHook.afterSwap.selector, 0);
    // }

}
