// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract testing123 {
    bytes32 response;
    function testing(string calldata test) external {
        response = keccak256(abi.encode(test));
    }
}