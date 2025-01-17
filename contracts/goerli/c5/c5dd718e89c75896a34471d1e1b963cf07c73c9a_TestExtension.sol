/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract TestExtension {

    error badSigner();
    error notEnoughtEth(uint need, uint value);
    error RevertFunction();

    uint private a;
    function d(uint _a) external {
        if( _a > 5) {
            revert notEnoughtEth(1,3);
        }
        else {
            a = _a;
        }
    }

    function badSignerCall(uint _b) external {
         if( _b > 5) {
            revert badSigner();
        }
        else {
            a = _b;
        }
    }

    function badSignerCall2(uint _b) external {
         if( _b > 5) {
            revert RevertFunction();
        }
        else {
            a = _b;
        }
    }
}