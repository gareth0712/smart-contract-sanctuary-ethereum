/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
 
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
 
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
 
}
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
 
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}
 
contract ghan is Context, IERC20, Ownable {
 
    using SafeMath for uint256;
 
    string private constant _name = "ghanin";//
    string private constant _symbol = "Ghan";//
    uint8 private constant _decimals = 9;
 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;  
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public launchBlock;
 
    //Buy Fee
    uint256 private _redisFeeOnBuy = 0;//
    uint256 private _taxFeeOnBuy = 5;//
    uint256 private _liqFeeOnBuy = 5;
 
    //Sell Fee
    uint256 private _redisFeeOnSell = 0;//
    uint256 private _taxFeeOnSell = 5;//
    uint256 private _liqFeeOnSell = 5;
 
    //Original Fee
    uint256 private _redisFee = _redisFeeOnBuy;
    uint256 private _taxFee = _taxFeeOnBuy;
    uint256 private _liqFee = _liqFeeOnBuy;
 
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;
    uint256 private _previousliqFee = _liqFee;

    //marketing + liquidity
    uint256 private _taxLiqFees;
    uint256 private _previoustaxLiqFees;
 
    mapping(address => bool) public bots;
    mapping(address => uint256) private cooldown;

    address payable private _marketingAddress = payable(  0xa51f157893be58D2B14b4d221b241c72BE186bEd);
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
 
    uint256 public _maxTxAmount = 1000000000 * 10**9; //
    uint256 public _maxWalletSize = 1000000000 * 10**9; //
    uint256 public _swapTokensAtAmount = 5000000 * 10**9; //
 
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event SwapAndLiquify(
      uint256 tokensSwapped,
      uint256 ethReceived,
      uint256 tokensIntoLiquidity
    );
 
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor(address tokenOwner) {
 
        _rOwned[_msgSender()] = _rTotal;

        _taxLiqFees = _taxFee + _liqFee;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());        
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        transferOwnership(tokenOwner);
        _transfer(msg.sender, tokenOwner, balanceOf(address(msg.sender)));
 
        
 
 
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
 
    function name() public pure returns (string memory) {
        return _name;
    }
 
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
 
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function showBuyReflectionFee() external view returns (uint256) {
        return _redisFeeOnBuy;
    }

    function showBuyMarketingFee() external view returns (uint256) {
        return _taxFeeOnBuy;
    }

    function showBuyLiquidityFee() external view returns (uint256) {
        return _liqFeeOnBuy;
    }

    function showSellReflectionFee() external view returns (uint256) {
        return _redisFeeOnSell;
    }

    function showSellMarketingFee() external view returns (uint256) {
        return _taxFeeOnSell;
    }

    function showSellLiquidityFee() external view returns (uint256) {
        return _liqFeeOnSell;
    }

    function maxTransaction() external view returns (uint256) {
        return _maxTxAmount;
    }

    function maxWallet() external view returns (uint256) {
        return _maxWalletSize;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }
 
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
 
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
 
    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0 && _liqFee == 0 && _taxLiqFees == 0) return;
 
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
        _previousliqFee = _liqFee;
        _previoustaxLiqFees = _taxLiqFees;
 
        _redisFee = 0;
        _taxFee = 0;
        _liqFee = 0;
        _taxLiqFees = 0;
    }
 
    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
        _liqFee = _previousliqFee;
        _taxLiqFees = _previoustaxLiqFees;
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }            

            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");
 
            if(block.number <= launchBlock && to != address(uniswapV2Router) && to != address(this)){   
                bots[to] = true;
            } 
 
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
 
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                contractTokenBalance = _swapTokensAtAmount;
                swapAndLiquify(contractTokenBalance);
            }
        }
 
        bool takeFee = true;
 
        //Transfer Tokens
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else { 
            
            if(from == uniswapV2Pair) {
                //Set Fee for Buys
                _redisFee = _redisFeeOnBuy;
                _taxLiqFees = _taxFeeOnBuy + _liqFeeOnBuy;                
            } if (to == uniswapV2Pair) { //Set Fee for Sells
                _redisFee = _redisFeeOnSell;
                _taxLiqFees = _taxFeeOnSell + _liqFeeOnSell;                
            } else { //other
                _redisFee = _redisFeeOnBuy;
                _taxLiqFees = _taxFeeOnBuy + _liqFeeOnBuy;  
                
            }
 
        }
 
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
      uint256 marFees = _taxFeeOnBuy + _taxFeeOnSell;
      uint256 liqFees = _liqFeeOnBuy + _liqFeeOnSell;
      uint256 totFees = marFees + liqFees;

      uint256 initialBalance = address(this).balance;
      swapTokensForEth(contractTokenBalance.mul(marFees).div(totFees));
      uint256 newEth = address(this).balance.sub(initialBalance);
      sendETHToFee(_marketingAddress, newEth);

      uint256 newTokenBalance = balanceOf(address(this));
      uint256 half = newTokenBalance.div(2);
      uint256 otherHalf = newTokenBalance.sub(half);
      swapTokensForEth(half);
      uint256 newEthBalance = address(this).balance.sub(initialBalance);
      addLiquidity(otherHalf, newEthBalance);

      emit SwapAndLiquify(half, newEthBalance, otherHalf);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
 
    function sendETHToFee(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
 
    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
        launchBlock = block.number + 7;
    } 
 
    function manualswap() external {
        require(_msgSender() == owner() || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require(_msgSender() == owner() || _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(_marketingAddress, contractETHBalance);
    }
 
    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
 
    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }
 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }
 
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
 
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    receive() external payable {}
 
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxLiqFees);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
 
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
 
    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxLiqFees
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxLiqFees).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
 
        return (tTransferAmount, tFee, tTeam);
    }
 
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
 
        return (rAmount, rTransferAmount, rFee);
    }
 
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
 
        return rSupply.div(tSupply);
    }
 
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
 
        return (rSupply, tSupply);
    }
 
    function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell, uint256 liqFeeOnBuy, uint256 liqFeeOnSell) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
 
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;

        _liqFeeOnBuy = liqFeeOnBuy;
        _liqFeeOnSell = liqFeeOnSell;
    }
 
    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 
    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }
 
 
    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    //set marketing wallet address
    function setMarketingAddress(address payable marketingAddress) external onlyOwner {
      _marketingAddress = marketingAddress;
    }

}