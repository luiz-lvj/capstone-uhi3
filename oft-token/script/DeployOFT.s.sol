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


        string memory name = "PEPE";

        address ArbEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        //address BaseEndpoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
        address WorldEndpoint = 0xBa8dF7424dAE9C2CDB4BC1aD2b63ABD97194fDb6;
        address UniEndpoint = 0xb8815f3f882614048CbE201a67eF9c6F10fe5035;

        address lzEndpoint = UniEndpoint;

        oft = new BoomOFT(name, name, lzEndpoint, owner);

        console.log("-------- OFT DEPLOYMENT --------");
        console.log("Chain Id: ", block.chainid);
        console.log("Name: ", name);
        console.log("OFT address: ", address(oft));
        
        vm.stopBroadcast();
        
    }
}