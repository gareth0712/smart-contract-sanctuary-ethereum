/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Modifier {
    modifier verificarAdmin() {
        require(msg.sender == owner, "No es el owner.");
        _;
    }

    uint256 totalSupply;
    address owner = 0xbC2568Ae7c08501B54D1f53b0A6FB149818feD9E;

    mapping(address => uint256) balances;
    event Transfer(address from, address to, uint256 value);

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "Mint to the zero address");

        totalSupply += _amount;
        balances[_account] += _amount;

        emit Transfer(address(0), _account, _amount);
    }

    bool public paused; // false
    modifier whenNotPaused() {
        require(!paused, "El contrato ha sido pausado");
        _;
    }

    function mintProtegidoPorModifier(address _account, uint256 _amount)
        public
        verificarAdmin
        whenNotPaused
    {
        _mint(_account, _amount);
    }

    function pausarContrato() public verificarAdmin {
        paused = true;
    }

    function quitarPausaContrato() public verificarAdmin {
        paused = false;
    }
}