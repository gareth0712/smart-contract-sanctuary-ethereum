pragma solidity 0.8.16;

contract BoxV2 {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    } 

    function increase() external {
        val -= 1;
    }

}