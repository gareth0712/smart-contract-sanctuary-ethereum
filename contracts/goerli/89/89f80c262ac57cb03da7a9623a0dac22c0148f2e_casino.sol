/**
 *Submitted for verification at Etherscan.io on 2022-12-25
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract casino {
// Struct to store information about a single bet
struct Bet {
    address payable player;
    uint256 amount;
    bool guess;
    bool revealed;
}

// Mapping to store all the placed bets
mapping(uint => Bet) public bets;

// Address of the contract owner
address public owner;

// Counter variable to store the number of bets placed
uint public betCounter;

// Event to be emitted when a bet is placed
event BetPlaced(uint index, address player, uint256 amount, bool guess);

// Event to be emitted when a bet is revealed and the result is determined
event BetResult(bool success, uint256 amount, address player);

// Event to be emitted when the contract owner withdraws funds
event FundsWithdrawn(uint256 amount);

// Contract constructor
constructor() public {
    owner = msg.sender;
    betCounter = 0;
}

// Place a new bet
function placeBet(bool _guess, uint256 _amount) public payable {
    require(_amount > 0, "Bet amount must be greater than 0");
    require(_amount <= msg.value, "Bet amount must be equal to or less than the sent value");
    require(_amount <= address(this).balance, "Contract balance must be greater than or equal to the bet amount");

    // Increment the bet counter and create a new bet
    uint betIndex = betCounter++;
    Bet storage newBet = bets[betIndex];
    newBet.player = payable(msg.sender);
    newBet.amount = _amount;
    newBet.guess = _guess;
    newBet.revealed = false;

    // Emit the BetPlaced event
    emit BetPlaced(betIndex, msg.sender, _amount, _guess);
}

// Reveal a bet and determine the result
function revealBet(uint _index) public {
    Bet storage bet = bets[_index];
    require(!bet.revealed, "Bet has already been revealed");
    require(msg.sender == bet.player, "Only the player who placed the bet can reveal it");

    // Determine the result of the bet (true = heads, false = tails)
    bool flipResult;
    if (uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 2 == 0) {
        flipResult = true;
    } else {
        flipResult = false;
    }
    

    // Calculate the winnings for the player
    uint256 winnings;
    if (flipResult == bet.guess) {
        winnings = bet.amount*1e18* 195 / 100;
    } else {
        winnings = 0;
    }

    // Pay out the winnings
    bet.player.transfer(winnings);

    address payable player = payable(bet.player);
  

    // Mark the bet as revealed
    bet.revealed = true;

    // Emit the BetResult event
    emit BetResult(flipResult == bet.guess, winnings, bet.player);

    
    
}

function systemWithdraw(uint256 amount) public {
    require(msg.sender == owner, "Only the contract owner can withdraw funds");
    require(amount <= address(this).balance, "withdraw amount exceed");
        payable(msg.sender).transfer(amount*1e18);
    }


}