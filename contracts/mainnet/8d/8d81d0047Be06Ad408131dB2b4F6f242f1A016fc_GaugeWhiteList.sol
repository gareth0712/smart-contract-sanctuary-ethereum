/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity ^0.8.11;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// verificator for create gauge contract (BaseV1-voter)

contract GaugeWhiteList is Ownable {
  bool public isEnabledVerification = true;

  mapping (address => bool) public isWhitelistedPool;
  mapping (address => bool) public isWhitelistedToken;

  // add pool in white list
  function addPool(address _pool) external onlyOwner {
    isWhitelistedPool[_pool] = true;
  }

  // remove pool from white list
  function removePool(address _pool) external onlyOwner {
    isWhitelistedPool[_pool] = false;
  }

  // add token in white list
  function addToken(address _token) external onlyOwner {
    isWhitelistedToken[_token] = true;
  }

  // remove token from white list
  function removeToken(address _token) external onlyOwner {
    isWhitelistedToken[_token] = false;
  }

  // enable verify function
  function enableVerification() external onlyOwner {
    isEnabledVerification = true;
  }

  // disable verify function
  function disableVerification() external onlyOwner {
    isEnabledVerification = false;
  }

  // return true if gauge can be created
  function verify(address token0, address token1, address pool)
    external
    view
    returns(bool)
  {
    if(!isEnabledVerification)
      return true;

    if(isWhitelistedPool[pool])
      return true;

    if(isWhitelistedToken[token0] || isWhitelistedToken[token1]){
      return true;
    }else {
      return false;
    }
  }
}