//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "./IGreeter.sol";

contract Greeter is IGreeter {
    string private greeting;

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