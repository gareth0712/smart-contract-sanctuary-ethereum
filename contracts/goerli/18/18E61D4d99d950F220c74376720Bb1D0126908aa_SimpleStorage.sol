/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  uint256 favoriteNumber;
  uint256 confirm0;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  // uint256[] public anArray;
  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addConfirm(uint _confirm0) public returns(uint256) {
    confirm0 = _confirm0 + 1;
    return confirm0;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}