// stake tokens
// unstake tokens
// issueRewards
// addAllowedTokens
// getEthValue

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    IERC20 public dappToken;

    address[] public allowedTokens;
    address[] public stakers;

    // tokenAddress => stakerAddress => amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    // userAddress => numberOfUniqueTokens
    mapping(address => uint256) public uniqueTokensStaked;
    // token => price feed address
    mapping(address => address) public tokenPriceFeedMap;

    constructor(address _dappToken) public {
        dappToken = IERC20(_dappToken);
    }

    function stakeTokens(uint256 _amount, address _token) public {
        // what tokens can be staked
        // how much can be staked
        require(_amount > 0, "Amount staked must be greater than 0.");
        require(tokenAllowed(_token), "Token isn't currently available.");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function issueTokenReward() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function unstakeTokens(address _token, uint256 _amount) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staked balance must be greater than 0");
        require(
            _amount <= balance,
            "Cannot withdraw more than they've staked."
        );
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] -
            _amount;

        if (stakingBalance[_token][msg.sender] <= 0) {
            uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
            if (uniqueTokensStaked[msg.sender] <= 0) {
                removeStaker(msg.sender);
            }
        }
    }

    function addAllowedToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenAllowed(address _token) public view returns (bool) {
        for (
            uint256 allowedIndex = 0;
            allowedIndex < allowedTokens.length;
            allowedIndex++
        ) {
            if (allowedTokens[allowedIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function updateUniqueTokensStaked(address _sender, address _token)
        internal
    {
        if (stakingBalance[_token][_sender] <= 0) {
            uniqueTokensStaked[_sender] = uniqueTokensStaked[_sender] + 1;
        }
    }

    function getUserTotalValue(address _user) internal view returns (uint256) {
        require(uniqueTokensStaked[_user] > 0, "User has no tokens staked");
        uint256 totalValue = 0;

        for (
            uint256 tokenIndex = 0;
            tokenIndex < allowedTokens.length;
            tokenIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(_user, allowedTokens[tokenIndex]);
        }

        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }

        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price) / (10**decimals);
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // retrieve from chainlink price feeds
        address priceFeedAddress = tokenPriceFeedMap[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMap[_token] = _priceFeed;
    }

    function removeStaker(address _user) internal {
        // we don't care about the order of the staker array here
        // so we'll copy the last element to the index to be removed
        // and delete the last elements
        for (
            uint256 stakerIndex = 0;
            stakerIndex < stakers.length;
            stakerIndex++
        ) {
            if (stakers[stakerIndex] == _user) {
                if (stakerIndex < stakers.length - 1) {
                    // if not the last item in the array, then copy last item to new location before deleting last item
                    stakers[stakerIndex] = stakers[stakers.length - 1];
                }
                stakers.pop();
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}