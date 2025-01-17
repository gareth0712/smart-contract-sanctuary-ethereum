// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./Ownable.sol";

contract JpegPalacePower is IERC20, Ownable {
    uint private _totalSupply;
    mapping(address => uint) private _balanceOf;
    mapping(address => mapping(address => uint)) private _allowance;
    string public name = "JpegPalace Power";
    string public symbol = "JPP";
    uint8 public decimals = 18;
    
    event PowerTransfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balance() public view returns(uint) {
        return _balanceOf[msg.sender];
    }

    function balanceOf(address account) public view returns(uint) {
        return _balanceOf[account];
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        _balanceOf[msg.sender] -= amount;
        _balanceOf[recipient] += amount;
        emit PowerTransfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        _allowance[sender][msg.sender] -= amount;
        _balanceOf[sender] -= amount;
        _balanceOf[recipient] += amount;
        emit PowerTransfer(sender, recipient, amount);
        return true;
    }

    function makePower(uint amount) external onlyOwner {
        _balanceOf[msg.sender] += amount;
        _totalSupply += amount;
        emit PowerTransfer(address(0), msg.sender, amount);
    }

    function burnPower(uint amount) external onlyOwner {
        _balanceOf[msg.sender] -= amount;
        _totalSupply -= amount;
        emit PowerTransfer(msg.sender, address(0), amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = payable(newOwner);
        emit OwnershipTransferred(owner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Ownable 
{    
    address payable public owner;
    
    constructor() {
        owner = payable(msg.sender);
    }

    event OwnershipTransferred(address indexed from, address indexed to);
    
    modifier onlyOwner() 
    {
        require(msg.sender == owner, "Function accessible only by the owner.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}