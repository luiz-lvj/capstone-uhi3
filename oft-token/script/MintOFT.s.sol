// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import { BoomOFT } from "../contracts/BooMOFT.sol";



contract DeployOFT is Script {

    BoomOFT public oft;
    

    function setUp() public {}

    function run() public {

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        address owner = 0x000ef5F21dC574226A06C76AAE7060642A30eB74;

        oft = BoomOFT(0x0000000000000000000000000000000000000000);

        oft.mint(owner, 100000000 ether);
        
        vm.stopBroadcast();
        
    }
}