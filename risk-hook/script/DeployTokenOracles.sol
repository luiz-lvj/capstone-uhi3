// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MockChainlinkDataFeed} from "./mocks/MockChainlinkDataFeed.sol";
import {MockERC20} from "./mocks/MockERC20.sol";


interface IRiskManager {
    function init() external;

    function owner() external view returns (address);

    function addWhitelistedToken(address token, address price_oracle, address vol_oracle) external;

    function allowedSwap(address user, int256 max_vol, address token_in, int256 token_in_amount, address token_out, int256 token_out_amount) external view returns (bool);

    error NotOwner(address, address);

    error TokenAlreadyWhitelisted(address);

    error TokenNotWhitelisted(address);
}


contract  InitWhitelistTokens is Script {


    

    function setUp() public {}

    function run() public {

        vm.startBroadcast();

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");

        //IRiskManager riskManager = IRiskManager(0x0c5A679F14D0572bd710F03e08766394120A75eC);

        MockERC20 token1 = new MockERC20("WBTC", "WBTC");

        MockChainlinkDataFeed priceOracle = new MockChainlinkDataFeed(100_000_0000); // 100,000 USD

        MockChainlinkDataFeed volOracle = new MockChainlinkDataFeed(200000); // 20%

        MockERC20 token2 = new MockERC20("WETH", "WETH");

        MockChainlinkDataFeed priceOracle2 = new MockChainlinkDataFeed(100_000_0000); // 100,000 USD

        MockChainlinkDataFeed volOracle2 = new MockChainlinkDataFeed(600000); // 60%

        console.log("WBTC address: ", address(token1));
        console.log("WBTC priceOracle address: ", address(priceOracle));
        console.log("WBTC volOracle address: ", address(volOracle));

        console.log("WETH address: ", address(token2));
        console.log("WETH priceOracle address: ", address(priceOracle2));
        console.log("WETH volOracle address: ", address(volOracle2));

        vm.stopBroadcast();
        
    }
}