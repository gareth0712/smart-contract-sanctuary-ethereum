/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Incrementer {
    uint256 public number;

    constructor(uint256 _initialNumber) {
        
        number = _initialNumber;
    }

    function increment(uint256 _value) public {
        number = number + _value;
    }

    function reset() public {
        number = 0;
    }
}