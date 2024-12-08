// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MockChainlinkDataFeed {

    int256 public mockedAnswer;

    constructor(int256 _answer) {
        mockedAnswer = _answer;
    }
    
    
    function latestRoundData()
    external
    view 
    returns (int256 answer){
        return mockedAnswer;
    }
    
}