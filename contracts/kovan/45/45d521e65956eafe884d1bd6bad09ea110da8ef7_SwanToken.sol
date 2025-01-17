/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SwanToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFee;
    mapping (address => bool) public _isNotSwapPair;
    mapping (address => address) public inviter;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 29000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public  _tTaxFeeTotal;

    string private _name = "Swan Finance Community Token";
    string private _symbol = "Swan";
    uint8  private _decimals = 18;

    uint256 public taxFee = 0;
    uint256 private _previousTaxFee = taxFee;

    uint256 private _totalFeeRatio=10000; 
    uint256 public marketFee =800; //800%
    uint256 public boardFee =50; //0.5%
    uint256 public fundFee =200;  //2%
    uint256 public liquidFee =300; //3%
    uint256 public returnBackFee =150; //1.5%

    uint256 public elseFee = marketFee+boardFee+fundFee+liquidFee+returnBackFee; //other total 15%
    uint256 private _previousElseFee = elseFee;


    address public mainAddr = address(0xF855101284b09df93236b24Ae8D481395Fb037Fd);
    address public boardAddr = address(0xC9D0d2FaD4e5b35A51256Dd644Bb0A2591b1AFD9);
    address public fundAddr = address(0x58e35f559c1ab2fAc8063cb4966B2dB2DD289fF9);
    address public liquidAddr = address(0x70c728Ae4b7493b19F997a98E34A5FeDF6DB814d);
    address public returnBackAddr = address(0xC19a725DA46432ea97f877f4E3d010d6b1ee1473); // return back address

    constructor () public {
        _isExcludedFee[mainAddr] = true;
        _isExcludedFee[address(this)] = true;

        _rOwned[mainAddr] = _rTotal;
        emit Transfer(address(0), mainAddr, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
        }
        _transferStandard(sender, recipient, amount, takeFee);
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTaxFee, uint256 tTransferAmount, uint256 tTaxFee, uint256 tElseFee)
             = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        emit Transfer(sender, recipient, tTransferAmount);

        if (!takeFee) {
            return;
        }

        uint256 _marketFee=tElseFee.mul(marketFee).div(elseFee);
        _takeInviterFee(sender, recipient, _marketFee); 
        uint256 _liquidFee=tElseFee.mul(liquidFee).div(elseFee);
        _takeLiquidity(sender, _liquidFee); 
        uint256 _boardFee=tElseFee.mul(boardFee).div(elseFee);
        _takeBoard(sender, _boardFee);
        uint256 _fundFee=tElseFee.mul(fundFee).div(elseFee);
        _takeFund(sender, _fundFee); 
        uint256 _returnBackFee=tElseFee.mul(returnBackFee).div(elseFee);
        _takeReturnBack(sender, _returnBackFee); 
        _reflectFee(rTaxFee, tTaxFee); 
    }

    function _takeInviterFee(
        address sender, address recipient, uint256 tAmount
    ) private {
        uint256 currentRate =  _getRate();
     
        address cur = sender;
        uint16[10] memory inviteRate = [1250, 1250, 1250, 1250, 1250, 1250, 625, 625, 625, 625];
        for (uint16 i = 0; i < inviteRate.length; i++) {
            uint16 rate = inviteRate[i];
            cur = inviter[cur];
            if (cur == address(0)) {
                cur = fundAddr; //transfer to fund pool
            }
            uint256 curTAmount = tAmount.mul(rate).div(_totalFeeRatio);
            uint256 curRAmount = curTAmount.mul(currentRate);
            _rOwned[cur] = _rOwned[cur].add(curRAmount);
            emit Transfer(sender, cur, curTAmount);
        }
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    
    function _takeBoard(address sender, uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[boardAddr] = _rOwned[boardAddr].add(rDev);
        emit Transfer(sender, boardAddr, tDev);
    }
    
    function _takeFund(address sender, uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[fundAddr] = _rOwned[fundAddr].add(rDev);
        emit Transfer(sender, fundAddr, tDev);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[liquidAddr] = _rOwned[liquidAddr].add(rLiquidity);
        emit Transfer(sender, liquidAddr, tLiquidity);
    }

    function _takeReturnBack(address sender, uint256 tReturnBack) private {
        uint256 currentRate =  _getRate();
        uint256 rReturnBack = tReturnBack.mul(currentRate);
        _rOwned[returnBackAddr] = _rOwned[returnBackAddr].add(rReturnBack);
        emit Transfer(sender, returnBackAddr, tReturnBack);
    }

    function setTaxFee(uint256 _taxFee) external onlyOwner {
        taxFee = _taxFee;
    }

    function setElseFee(uint256 _marketFee,uint256 _boardFee,uint256 _fundFee,uint256 _liquidFee,uint256 _returnBackFee) external onlyOwner {
        uint256 elseTotal= _marketFee+_boardFee+_fundFee+_liquidFee+_returnBackFee;
        require(elseTotal<_totalFeeRatio,"grant than total ratio");
        marketFee=_marketFee;
        boardFee=_boardFee;
        fundFee=_fundFee;
        liquidFee=_liquidFee;
        returnBackFee=_returnBackFee;
        elseFee=elseTotal;
    }

    function setExcludedFee(address addr, bool state) public onlyOwner {
        _isExcludedFee[addr] = state;
    }
    
    function setMainAddr(address addr) public onlyOwner {
        mainAddr = addr;
    }

    function setFeeAddr(address _boardAddr,address _liquidAddr,address _fundAddr,address _returnBackAddr) public onlyOwner {
        boardAddr = _boardAddr;
        liquidAddr=_liquidAddr;
        fundAddr=_fundAddr;
        returnBackAddr=_returnBackAddr;
    }

    function _reflectFee(uint256 rTaxFee, uint256 tTaxFee) private {
        _rTotal = _rTotal.sub(rTaxFee);
        _tTaxFeeTotal = _tTaxFeeTotal.add(tTaxFee);
    }
    
    function _getValues(uint256 tAmount) private view returns 
    (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTaxFee, uint256 tElseFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTaxFee) = 
            _getRValues(tAmount, tTaxFee, tElseFee, _getRate());
        return (rAmount, rTransferAmount, rTaxFee, tTransferAmount, tTaxFee, tElseFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tTaxFee = calculateTaxFee(tAmount);
        uint256 tElseFee = calculateElseFee(tAmount);
        
        uint256 tTransferAmount = tAmount.sub(tTaxFee).sub(tElseFee);
        return (tTransferAmount, tTaxFee, tElseFee);
    }

    function _getRValues(uint256 tAmount, uint256 tTaxFee, uint256 tElseFee, uint256 currentRate) 
    private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTaxFee = tTaxFee.mul(currentRate);
        uint256 rEleseFee = tElseFee.mul(currentRate);

        uint256 rTransferAmount = rAmount.sub(rTaxFee).sub(rEleseFee);
        return (rAmount, rTransferAmount, rTaxFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFee).div(_totalFeeRatio);
    }

    function calculateElseFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(elseFee).div(_totalFeeRatio);
    }

    function setIsNotSwapPair(address addr, bool state) public onlyOwner{
        _isNotSwapPair[addr] = state;
    }

    function setInviter(address a1, address a2) public onlyOwner{
        require(a1 != address(0));
        inviter[a1] = a2;
    }

    function removeAllFee() private {
        if(taxFee == 0 && elseFee == 0) return;

        _previousTaxFee = taxFee;
        _previousElseFee = elseFee;

        taxFee = 0;
        elseFee = 0;
    }

    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        elseFee = _previousElseFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from, address to, uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
       
        bool takeFee = true;

        if(_isExcludedFee[from] || _isExcludedFee[to]) {
            takeFee = false;
        }
        if (_isNotSwapPair[from]){
            takeFee = false;
        }
        if ((isContract(from) && isContract(from)) || (!isContract(from) && !isContract(from))){
            takeFee = false;
        } 
        bool shouldInvite = (balanceOf(to) == 0 && inviter[to] == address(0) 
            && !isContract(from) && !isContract(to));

        _tokenTransfer(from, to, amount, takeFee);

        if (shouldInvite) {
            inviter[to] = from;
        }
    }

}