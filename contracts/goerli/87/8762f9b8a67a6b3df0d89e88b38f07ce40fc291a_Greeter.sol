/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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