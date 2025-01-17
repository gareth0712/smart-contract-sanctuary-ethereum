/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Introducer is Ownable {
    mapping(address => uint256) uplinesCode;
    mapping(address => uint256) myCode;
    mapping(uint256 => address) code2address;

    uint256 public code;

    constructor() {
        code = 1000;
        uplinesCode[msg.sender] = code;
        code2address[code] = msg.sender;
        myCode[msg.sender] = code;
    }

    event Code(uint256 MyCode);

    function register(uint256 _upline) public {
        code++;
        require(myCode[msg.sender] == 0, "Already registered");
        myCode[msg.sender] = code;
        code2address[code] = msg.sender;
        uplinesCode[msg.sender] = _upline;
        emit Code(code);
    }

    function viewMyCode() public view returns (uint256) {
        return myCode[msg.sender];
    }

    function viewMyUplinesCode() public view returns (uint256) {
        return uplinesCode[msg.sender];
    }

    function viewMyUplinesAddress() public view returns (address) {
        return code2address[viewMyUplinesCode()];
    }

    uint256 introducerReward100x;

    function setIntroducerReward(uint256 _100x) public {
        introducerReward100x = _100x;
    }
}

contract PredictionMarket is Ownable, Introducer {
    enum Status {
        Active,
        Started,
        ResultDone
    }
    enum Result {
        Won1,
        Draw,
        Won2
    }
    Status status;
    Status constant defaultStatus = Status.Active;
    Result constant defaultResult = Result.Draw;
    //enum Side { KXIP, RCB }
    struct Game {
        //uint gameId;
        Status currentStatus;
        string team1;
        string team2;
        Result finalResult;
        // bool hasWinner;
        // bool winnerTeam1;
    }
    //   struct Result {
    //     Side winner;
    //     Side loser;
    //   }
    //Result result;
    //   bool matchStarted = false;
    //   bool matchFinished = false;
    uint256 public gameId;
    mapping(uint256 => Game) gameIds;
    mapping(uint256 => mapping(Result => uint256)) public bets;
    mapping(address => mapping(uint256 => mapping(Result => uint256))) betsPerGambler;
    mapping(uint256 => string) gameWinner;
    mapping(uint256 => string) gameLoser;
    //   mapping(Side => uint) public bets;
    //   mapping(address => mapping(Side => uint)) public betsPerGambler;
    //   address payable owner;

    //   constructor() {
    //     owner() = msg.sender;
    //   }
    event CreateGame(uint256 Id, uint256 Time, string t1, string t2);
    event EditGame(uint256 Id, uint256 Time, string t1, string t2);

    function getGame(uint256 _gameId) public view returns(Game memory game) {
        return gameIds[_gameId];
    }
    function createGame(string memory _t1, string memory _t2) public onlyOwner {
        gameId++;
        gameIds[gameId] = Game(defaultStatus, _t1, _t2, defaultResult);
        emit CreateGame(gameId, block.timestamp, _t1, _t2);
    }

    function editGameInfo(uint256 _gameId, string memory _t1, string memory _t2) public onlyOwner {
        gameIds[_gameId] = Game(defaultStatus, _t1, _t2, defaultResult);
        emit EditGame(_gameId, block.timestamp, _t1, _t2);
    }

    uint256 public totalTrade;

    function placeBet(uint256 _gameId, Result _result) external payable {
        require(msg.value>0, "Staked amount cannot be 0");
        require(_gameId<=gameId, "Game Id does not exist");
        require(
            gameIds[_gameId].currentStatus == Status.Active,
            "You cant bid now"
        );
        //require(myCode[msg.sender]!=0, "Register to get attractive rewards");
        if (myCode[msg.sender] != 0) {
            bets[_gameId][_result] += msg.value;
            betsPerGambler[msg.sender][_gameId][_result] += msg.value;
            totalTrade += (msg.value);
            payable(viewMyUplinesAddress()).transfer(
                ((msg.value) * introducerReward100x) / 10000
            );
            payable(msg.sender).transfer(
                ((msg.value) * introducerReward100x) / 20000
            );
        } else {
            bets[_gameId][_result] += msg.value;
            betsPerGambler[msg.sender][_gameId][_result] += msg.value;
        }
    }

    function stopBets(uint256 _gameId) external onlyOwner {
        gameIds[_gameId].currentStatus = Status.Started;
    }

    function betsPosition(uint256 _gameId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        //   string memory t1 = gameIds[_gameId].team1;
        //   string memory t2 = gameIds[_gameId].team2;
        return (
            bets[_gameId][Result.Won1],
            bets[_gameId][Result.Draw],
            bets[_gameId][Result.Won2]
        );
    }

    function betsPositionRatio(uint256 _gameId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        //   string memory t1 = gameIds[_gameId].team1;
        //   string memory t2 = gameIds[_gameId].team2;
        uint256 x1 = bets[_gameId][Result.Won1];
        uint256 x2 = bets[_gameId][Result.Draw];
        uint256 x3 = bets[_gameId][Result.Won2];
        if (x1 + x2 + x3 == 0) {
            return (0, 0, 0);
        } else {
            return (
                ((x1 * 100) / (x1 + x2 + x3)),
                ((x2 * 100) / (x1 + x2 + x3)),
                ((x3 * 100) / (x1 + x2 + x3))
            );
        }
    }

    function viewTotalTrade() public view returns (uint256) {
        return totalTrade;
    }

    function getGameStatus(uint256 _gameId) public view returns (Status) {
        return gameIds[_gameId].currentStatus;
    }

    event MatchOver(string Comment);

    function matchOver(
        uint256 _gameId,
        Result _result,
        bool _hasWinner,
        bool _winnerTeam1
    ) external onlyOwner {
        gameIds[_gameId].currentStatus = Status.ResultDone;
        gameIds[_gameId].finalResult = _result;

        // gameIds[_gameId].hasWinner = _hasWinner;
        // if(gameIds[_gameId].hasWinner){
        //     gameIds[_gameId].winnerTeam1 = _winnerTeam1;
        //     if(_winnerTeam1){
        //         gameWinner[_gameId] = gameIds[_gameId].team1;
        //         gameLoser[_gameId] = gameIds[_gameId].team2;
        //         emit MatchOver("match result announced, please collect your reward");
        //     }else {
        //         gameWinner[_gameId] = gameIds[_gameId].team2;
        //         gameLoser[_gameId] = gameIds[_gameId].team1;
        //         emit MatchOver("Match abandoned or draw, please collect your refund");
        //     }
        // }
    }

    uint256 public bonus = 80;

    function setBonus(uint256 _bonus)
        public
        onlyOwner
        returns (string memory, uint256)
    {
        require(_bonus < 100, "Bonus to be less than 100");
        bonus = _bonus;
        return ("Bonus for games, in percentage, is :", bonus);
    }

    mapping(uint256 => mapping(address => bool)) claimed;

    function withdrawGain(uint256 _gameId) external returns (uint256) {
        require(
            gameIds[_gameId].currentStatus == Status.ResultDone,
            "Result not reported yet"
        );

        uint256 x1 = bets[_gameId][Result.Won1];
        uint256 x2 = bets[_gameId][Result.Draw];
        uint256 x3 = bets[_gameId][Result.Won2];

        uint256 gamblerBet = betsPerGambler[msg.sender][_gameId][
            gameIds[_gameId].finalResult
        ];
        require(gamblerBet > 0, "You don't have any winning bet");
        require(!claimed[_gameId][msg.sender], "Already claimed");
        claimed[_gameId][msg.sender] = true;
        uint256 totalBets = x1 + x2 + x3;
        uint256 gain100x;
        if (gameIds[_gameId].finalResult == Result.Won1) {
            gain100x = ((totalBets - x1) * gamblerBet * bonus) / x1;
        } else if (gameIds[_gameId].finalResult == Result.Draw) {
            gain100x = ((totalBets - x2) * gamblerBet * bonus) / x2;
        } else {
            gain100x = ((totalBets - x3) * gamblerBet * bonus) / x3;
        }
        

        // uint gain100x = bets[_gameId][loser] * gamblerBet*bonus/(bets[_gameId][winner]);
        payable(msg.sender).transfer((gamblerBet * 100 + gain100x) / 100);
        return gain100x;
    
        // }else {
        //     string memory t1 = gameIds[_gameId].team1;
        //     string memory t2 = gameIds[_gameId].team2;
        //     uint myTotalBets = betsPerGambler[msg.sender][_gameId][t1] + betsPerGambler[msg.sender][_gameId][t2];
        //     payable(msg.sender).transfer(myTotalBets);
        //     return myTotalBets;
    }

    function removeAllEther() public onlyOwner {
        payable(owner()).transfer(viewBalance());
    }

    function removeEther(uint256 _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
    }

    function viewBalance() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {}

    receive() external payable {}
}