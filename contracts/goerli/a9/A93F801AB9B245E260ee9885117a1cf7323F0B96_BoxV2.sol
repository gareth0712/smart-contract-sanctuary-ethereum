// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint public val;

    function initialize(uint _val) external {
        val = _val;
    }
}

contract BoxV2 {
    uint public val;

    function inc() external {
        val += 1;
    }
}