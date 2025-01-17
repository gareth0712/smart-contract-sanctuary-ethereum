/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


contract Greeter {
    string greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}