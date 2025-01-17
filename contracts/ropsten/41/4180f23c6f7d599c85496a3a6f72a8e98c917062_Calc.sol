/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 < 0.9.0;

contract Calc{
    //宣告不可見的變數
    int private result;

    function add(int a,int b) public returns(int c){
        result = a + b;
        c = result;
    } 

    function min(int a , int b) public returns (int){
        result  = a - b;
        return result;
    }

    function mul(int a , int b) public returns (int){
        result  = a * b;
        return result;
    }
    function div(int a , int b) public returns (int){
        result  = a / b;
        return result;
    }
    //view僅供觀看值
    function getresult() public view returns(int){
        return result;
    }
}