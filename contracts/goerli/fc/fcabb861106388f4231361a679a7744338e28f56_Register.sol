/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Register {

    string private info;
    function getinfo() public view returns (string memory) {

        return info;
    }
   
    function setinfo(string memory _info) public {
       info= _info;
   }

}