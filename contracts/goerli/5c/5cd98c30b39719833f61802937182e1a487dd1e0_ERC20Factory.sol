// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./ConfigurableERC20Upgradable.sol";
import "./ClonableFactory.sol";

interface IHasRegistration {
  function isRegistered(address _contract, uint256 _type) external returns (bool);
  function registerContract(address _contract, uint _type) external;
}

contract ERC20Factory is ClonableFactory {

  address public handlerAddress;

  function initialize() virtual override public initializer {
    __Ownable_init();
    factoryType = "ERC20";
  }

  function initializeStage2(address _handlerAddress) public onlyOwner {
    handlerAddress = _handlerAddress;
    ClonableFactory.initialize();
  }

  function implement() virtual override internal returns(address) {
    return address(new ConfigurableERC20Upgradable());
  }

  function updateHandler(address _handlerAddress) public onlyOwner {
    handlerAddress = _handlerAddress;
  }

  function afterClone(address newOwner, address clone) internal override onlyOwner {
    if (IHasRegistration(handlerAddress).isRegistered(address(this), 8)) { // if factory registered with handler
      IHasRegistration(handlerAddress).registerContract(clone, 4);
    }
    IHasRegistration(clone).registerContract(handlerAddress, 3); // register handler on erc721
    OwnableUpgradeable(clone).transferOwnership(newOwner); // transfer to newOwner
  }

  function version() virtual override public view returns (uint256 _version) {
    return 1;
  }

}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./Clonable.sol";
abstract contract ClonableFactory is OwnableUpgradeable {

    using SafeMath for uint256;

    struct ImplementationsRecord {
        uint256 version;
        address implementation;
        uint256 contractVersion;
    }

    address public CurrentImplementation;
    ImplementationsRecord[] public AllImplementations;

    event CloneCreated(address indexed newThingAddress, address indexed libraryAddress);
    address[] internal Clones;
    string[] private Names;
    string public factoryType;

    function initialize() public virtual onlyOwner {
        updateImplementation();
    }

    function version() public view virtual returns (uint256) {
        return 1;
    }

    function versions() public view returns (uint256 _version) {
        return AllImplementations.length;
    }

    function updateImplementation() public onlyOwner {
        CurrentImplementation = implement();
        IClonable(CurrentImplementation).initialize();
        AllImplementations.push(ImplementationsRecord(AllImplementations.length.add(1), address(CurrentImplementation), IClonable(CurrentImplementation).version()));
    }

    function implement() internal virtual returns(address);
    function afterClone(address,address) internal virtual;

    function getClones() public view returns (address[] memory) {
        return Clones;
    }
    function createClone(address _newOwner) public onlyOwner {
        address clone = ClonesUpgradeable.clone(CurrentImplementation);
        handleClone(clone, _newOwner);
    }

    function createCloneAtVersion(address _newOwner, uint256 _version) public onlyOwner {
        address clone = ClonesUpgradeable.clone(AllImplementations[_version.sub(1)].implementation);
        handleClone(clone, _newOwner);
    }

    function handleClone(address clone, address _newOwner) internal {
        IClonable(clone).initialize();
        Clones.push(clone);
        emit CloneCreated(clone, CurrentImplementation);
        afterClone(_newOwner, clone);
    }

    function transferCloneOwnership(address clone, address newOwner) public onlyOwner {
        OwnableUpgradeable(clone).transferOwnership(newOwner);
    }

}

/**
 *Submitted for verification at polygonscan.com on 2021-06-30
*/

//  SPDX-License-Identifier: MIT

/*
   _____             __ _                       _     _      
  / ____|           / _(_)                     | |   | |     v3
 | |     ___  _ __ | |_ _  __ _ _   _ _ __ __ _| |__ | | ___ 
 | |    / _ \| '_ \|  _| |/ _` | | | | '__/ _` | '_ \| |/ _ \
 | |___| (_) | | | | | | | (_| | |_| | | | (_| | |_) | |  __/
  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|_.__/|_|\___|
                           __/ |                             
  ______ _____   _____ ___|___/_                             
 |  ____|  __ \ / ____|__ \ / _ \                            
 | |__  | |__) | |       ) | | | |                           
 |  __| |  _  /| |      / /| | | |                           
 | |____| | \ \| |____ / /_| |_| |                           
 |______|_|  \_\\_____|____|\___/ 
 
 By the team that brought you:
  --- > Circuits of Value (http://circuitsofvalue.com)
  --- > Emblem Vault (https://emblem.finance)
  
 Documentation:
  --- > Github (https://github.com/EmblemLabs/ConfigurableERC20)
  
 UI:
  --- > (https://emblemlabs.github.io/ConfigurableERC20/)
*/

pragma solidity ^0.8.4;
import "./SafeMath.sol";
import "./HasRegistration.sol";
import "./IERC20.sol";
import "./IHandlerCallback.sol";
import "./UpgradableERC20.sol";

contract Configurable is HasRegistration, UpgradableERC20 {
    using SafeMath for uint256;

    address private governance;
    bool internal _transferable;
    bool internal _burnable;
    bool internal _visible;
    bool internal _allowPrivateTransactions;
    bool internal _locked;
    bool internal _forever;
    uint256 internal _lockBlock;

    mapping(address => bool) internal minters;
    mapping(address => bool) internal viewers;

    function upgradeFrom(address oldContract) public onlyOwner notLocked virtual override {
       UpgradableERC20.upgradeFrom(oldContract);
    }
    function makeEvents(address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) public onlyOwner notLocked override {
        EventableERC20.makeEvents(_from, _to, amounts);
    }

    function _isGoverner() internal view returns (bool) {
        return _msgSender() == governance || _msgSender() == owner();
    }

    function _isViewer() internal view returns (bool) {
        return viewers[_msgSender()] || _msgSender() == owner();
    }

    function _isMinter() internal view returns (bool) {
        return minters[_msgSender()] || _msgSender() == owner();
    }

    function transferable() public view returns (bool) {
        return _transferable;
    }

    function burnable() public view returns (bool) {
        return _burnable;
    }

    function visible() public view returns (bool) {
        return _visible;
    }

    function visibleOrAdmin() public view returns (bool) {
        return _visible || _isGoverner();
    }

    function allowPrivateTransactions() public view returns (bool) {
        return _allowPrivateTransactions;
    }

    function blockNumberLocked() public view returns (bool) {
        return _lockBlock != 0 && block.number < _lockBlock;
    }

    function locked() public view returns (bool) {
        return _locked || blockNumberLocked();
    }

    function lockedPermenantly() public view returns (bool) {
        return locked() && _forever;
    }

    function blocksTillUnlock() public view returns (uint256) {
        if (_lockBlock > block.number) {
            return _lockBlock.sub(block.number);
        } else {
            return 0;
        }
    }

    modifier isTransferable() {
        require(_transferable, "Contract does not allow transfering");
        _;
    }

    modifier isBurnable() {
        require(_burnable, "Contract does not allow burning");
        _;
    }

    modifier isVisibleOrCanView() {
        require(
            _visible || _isViewer() || _isGoverner(),
            "Contract is private and you are not Governer or on viewers list"
        );
        _;
    }

    modifier canSendPrivateOrGoverner() {
        require(
            _allowPrivateTransactions || _isGoverner(),
            "Contract cannot send private transactions"
        );
        _;
    }

    modifier onlyOwner() override {
        require(_isGoverner() || canBypass(), "Sender is not Governer");
        _;
    }
    modifier notLocked() {
        require(!locked(), "Contract is locked to governance changes");
        _;
    }

    modifier canMint() {
        require(_isMinter(), "No Minting Privilages");
        _;
    }

    function unLock() public onlyOwner {
        require(
            !lockedPermenantly(),
            "Contract locked forever to governance changes"
        );
        require(
            !blockNumberLocked(),
            "Contract has been locked until a blocknumber"
        );
        require(locked(), "Contract not locked");
        _locked = false;
    }

    function lockForever() public onlyOwner {
        require(
            !lockedPermenantly(),
            "Contract locked forever to governance changes"
        );
        require(
            !blockNumberLocked(),
            "Contract has been locked until a blocknumber"
        );
        _locked = true;
        _forever = true;
    }

    function lockTemporarily() public onlyOwner notLocked {
        _locked = true;
    }

    function lockTemporarilyTillBlock(uint256 blockNumber) public onlyOwner notLocked {
        require(
            block.number < blockNumber,
            "Provided Block numbner is in the past"
        );
        _lockBlock = blockNumber;
    }

    function toggleBurnable() public onlyOwner notLocked {
        _burnable = !_burnable;
    }

    function toggleTransferable() public onlyOwner notLocked {
        _transferable = !_transferable;
    }

    function toggleVisibility() public onlyOwner notLocked {
        _visible = !_visible;
    }

    function togglePrivateTransferability() public onlyOwner notLocked {
        _allowPrivateTransactions = !_allowPrivateTransactions;
    }

    function setGovernance(address _governance) public onlyOwner notLocked {
        _setGovernance(_governance);
    }
    /* For compatibility with Ownable */
    function transferOwnership(address _governance) public override onlyOwner notLocked {
        OwnableUpgradeable.transferOwnership(_governance);
        _setGovernance(_governance);

    }
    function _setGovernance(address _governance) internal {
        minters[governance] = false; // Remove old owner from minters list
        viewers[governance] = false; // Remove old owner from viewers list
        minters[_governance] = true; // Add new owner to minters list
        viewers[_governance] = true; // Add new owner to viewers list
        governance = _governance; // Set new owner
    }
}

contract ERC20 is Configurable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply()
        public
        view
        isVisibleOrCanView
        returns (uint256)
    {
        return UpgradableERC20.totalSupplyHook(_totalSupply);
    }

    function balanceOf(address account)
        public
        view
        isVisibleOrCanView
        returns (uint256)
    {
        return UpgradableERC20.balanceOfHook(account, _balances);
    }

    function allowance(address _owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        public

        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public isTransferable returns (bool) {
        _transferFromPrivate(sender, recipient, amount, visible());
        return true;
    }

    function _transferFromPrivate(
        address sender,
        address recipient,
        uint256 amount,
        bool _private
    ) internal isTransferable returns (bool) {
        _transferPrivate(sender, recipient, amount, _private);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public

        isTransferable
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal isTransferable {
        _transferPrivate(sender, recipient, amount, !visible());
    }

    function _transferPrivate(
        address sender,
        address recipient,
        uint256 amount,
        bool _private
    ) internal isTransferable {
        require(sender != address(0), "ERC20: transfer from the zero address");
        uint256 pastSenderBalance = 0;
        uint256 pastRecipientBalance = 0;
        bool hasAllowance = _allowances[sender][_msgSender()] >= amount;
        bool _canBypass = canBypass();
        require(sender == _msgSender() || hasAllowance || _canBypass, "ERC20: transfer amount exceeds allowance or not bypassable");
        if (hasAllowance) {
            _allowances[sender][_msgSender()] = _allowances[sender][_msgSender()].sub(amount);
        }
        
        (pastSenderBalance, pastRecipientBalance) = UpgradableERC20.transferHook(sender, recipient, _balances);
        

        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(sender, recipient, amount, IHandlerCallback.CallbackType.TRANSFER);
        }
        if (!_private) {
            emit Transfer(sender, recipient, amount);
            UpgradableERC20.transferEventHook(sender, recipient, pastSenderBalance, pastRecipientBalance);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);

        amount = UpgradableERC20.mintHook(account, amount);
        
        _balances[account] = _balances[account].add(amount);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(address(0), account, amount, IHandlerCallback.CallbackType.MINT);  
        }
        if (visible()) {
            emit Transfer(address(0), account, amount);
        }
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        if (registeredOfType[3].length > 0  && registeredOfType[3][0] != address(0)) {
            IHandlerCallback(registeredOfType[3][0]).executeCallbacks(account, address(0), amount, IHandlerCallback.CallbackType.BURN);  
        }
        if (visible()) {
            emit Transfer(account, address(0), amount);
        }
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        if (visible()) {
            emit Approval(_owner, spender, amount);
        }
    }
}

contract ERC20Detailed is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
}

contract ConfigurableERC20Upgradable is ERC20, ERC20Detailed {
    using SafeMath for uint256;

    function initialize() public initializer {
        __Ownable_init();
        Configurable._transferable = true;
        Configurable._burnable = true;
        Configurable._visible = true;
        Configurable._allowPrivateTransactions = false;
        Configurable._locked = false;
        Configurable._forever = false;
        Configurable._lockBlock = 0;
    }

    function transfer(address to, uint256 amount, bool _private) public isTransferable canSendPrivateOrGoverner {
        _transferPrivate(_msgSender(), to, amount, _private);
    }

    function mint(address account, uint256 amount) public canMint notLocked {
        _mint(account, amount);
    }

    function burn(uint256 amount) public isBurnable notLocked {
        _burn(_msgSender(), amount);
    }

    function changeContractDetails(string memory _name, string memory _symbol, uint8 _decimals) public onlyOwner notLocked {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function addMinter(address _minter) public onlyOwner notLocked {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) public onlyOwner notLocked {
        minters[_minter] = false;
    }

    function addViewer(address _viewer) public onlyOwner notLocked {
        viewers[_viewer] = true;
    }

    function removeViewer(address _viewer) public onlyOwner notLocked {
        viewers[_viewer] = false;
    }

    function version() public pure returns (uint256) { 
        return 3;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IClonable {
    function initialize() external;
    function version() external returns(uint256);  
}
abstract contract Clonable {

    function initialize() public virtual;

    function version() public pure virtual returns (uint256) {
        return 1;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    modifier onlyOwner() virtual {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./IsBypassable.sol";

contract HasRegistration is IsBypassable {

    mapping(address => uint256) public registeredContracts; // 0 EMPTY, 1 ERC1155, 2 ERC721, 3 HANDLER, 4 ERC20, 5 BALANCE, 6 CLAIM, 7 UNKNOWN, 8 FACTORY, 9 STAKING, 10 BYPASS
    mapping(uint256 => address[]) internal registeredOfType;

    modifier isRegisteredContract(address _contract) {
        require(registeredContracts[_contract] > 0, "Contract is not registered");
        _;
    }

    modifier isRegisteredContractOrOwner(address _contract) {
        require(registeredContracts[_contract] > 0 || owner() == _msgSender(), "Contract is not registered nor Owner");
        _;
    }

    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        address[] storage arr = registeredOfType[registeredContracts[_contract]];
        arr[index] = arr[arr.length - 1];
        arr.pop();
        delete registeredContracts[_contract];
    }

    function isRegistered(address _contract, uint256 _type) public view returns (bool) {
        return registeredContracts[_contract] == _type;
    }

    function getAllRegisteredContractsOfType(uint256 _type) public view returns (address[] memory) {
        return registeredOfType[_type];
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./EventableERC20.sol";

interface IUpgradableERC20 {

    function upgradeFrom(address oldContract) external;
}

abstract contract UpgradableERC20 is IUpgradableERC20, EventableERC20  {
    using SafeMath for uint256;

    bool internal _isUpgrade;
    address public upgradedFrom;
    uint256 private _supplyMoved;

    mapping(address => bool) public seen;

    function isUpgrade() public view returns (bool) {
        return _isUpgrade;
    }

    function upgradeFrom(address oldContract) public virtual override {
        require(!_isUpgrade, "Contract already an upgrade");
        require(oldContract != address(0), "Invalid Upgrade");
        _isUpgrade = true;
        upgradedFrom = oldContract;
    }

    function transferHook(address sender, address recipient, mapping(address => uint256) storage _balances) internal returns (uint256, uint256) {
        uint256 pastSenderBalance = 0;
        uint256 pastRecipientBalance = 0;

        if (isUpgrade()) {
            if (!seen[sender]) {
                seen[sender] = true;
                pastSenderBalance = IERC20(upgradedFrom).balanceOf(sender);
                _supplyMoved = _supplyMoved.add(pastSenderBalance);
                _balances[sender] = _balances[sender].add(pastSenderBalance);
            }
            if (!seen[recipient]) {
                seen[recipient] = true;
                pastRecipientBalance = IERC20(upgradedFrom).balanceOf(recipient);
                _supplyMoved = _supplyMoved.add(pastRecipientBalance);
                _balances[recipient] = _balances[recipient].add(pastRecipientBalance);
            }
        } else {
            if (!seen[sender]) {
                seen[sender] = true;
            }
            if (!seen[recipient]) {
                seen[recipient] = true;
            }
        }
        return (pastSenderBalance, pastRecipientBalance);
    }

    function transferEventHook(address sender, address recipient, uint256 pastSenderBalance, uint256 pastRecipientBalance) internal {
        if (pastSenderBalance > 0) {
                emit Transfer(address(0), sender, pastSenderBalance);
            }
            if (pastRecipientBalance >0) {
                emit Transfer(address(0), recipient, pastRecipientBalance);
            }
    }

    function totalSupplyHook(uint256 _totalSupply) internal view returns(uint256) {
        return isUpgrade() ? (IERC20(upgradedFrom).totalSupply() - _supplyMoved) + (_totalSupply + _supplyMoved) : _totalSupply;
    }

    function balanceOfHook(address account,  mapping(address => uint256) storage _balances) internal view returns(uint256) {
        return (isUpgrade() && !seen[account]) ? IERC20(upgradedFrom).balanceOf(account):  _balances[account];
    }

    function mintHook(address account, uint256 amount) internal returns (uint256) {
        if (isUpgrade()) {
            if (!seen[account]) {
                seen[account] = true;
                uint256 pastBalance = IERC20(upgradedFrom).balanceOf(account);
                _supplyMoved = _supplyMoved.add(pastBalance);
                amount = amount.add(pastBalance);
            }
        } else {
            if (!seen[account]) {
                seen[account] = true;
            }
        }
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
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

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

interface IHandlerCallback {
    enum CallbackType {
        MINT, TRANSFER, CLAIM, BURN, FALLBACK
    }

    struct Callback {
        address vault;
        address registrant;
        address target;
        bytes4 targetFunction;
        bool canRevert;
    }
    function executeCallbacksInternal(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeCallbacks(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeStoredCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) external;
    
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "./IsClaimable.sol";

abstract contract IsBypassable is IsClaimable {

    bool byPassable;
    mapping(address => mapping(bytes4 => bool)) byPassableFunction;
    mapping(address => mapping(uint256 => bool)) byPassableIds;

    modifier onlyOwner virtual override {
        bool _canBypass = byPassable && byPassableFunction[_msgSender()][msg.sig];
        require(owner() == _msgSender() || _canBypass, "Not owner or able to bypass");
            _;
    }

    modifier onlyOwnerOrBypassWithId(uint256 id) {
        require (owner() == _msgSender() || (id != 0 && byPassableIds[_msgSender()][id] ), "Invalid id");
            _;
    }

    function canBypass() internal view returns(bool) {
        return (byPassable && byPassableFunction[_msgSender()][msg.sig]);
    }

    function canBypassForTokenId(uint256 id) internal view returns(bool) {
        return (byPassable && canBypass() && byPassableIds[_msgSender()][id]);
    }

    function toggleBypassability() public onlyOwner {
      byPassable = !byPassable;
    }

    function addBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = true;
        if (id != 0) {
            byPassableIds[who][id] = true;
        }        
    }

    function removeBypassRule(address who, bytes4 functionSig, uint256 id) public onlyOwner {
        byPassableFunction[who][functionSig] = false;
        if (id !=0) {
            byPassableIds[who][id] = true;
        }
    }
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./OwnableUpgradeable.sol";
abstract contract IsClaimable is OwnableUpgradeable {

    bool public isClaimable;

    function toggleClaimable() public onlyOwner {
        isClaimable = !isClaimable;
    }
   
}

// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IEventableERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function makeEvents(address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) external;
}

abstract contract EventableERC20 is IEventableERC20 {
    function makeEvents(address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) public virtual override {
        _handleEventFromLoops(_from, _to, amounts);
    }

    function _handleEventFromLoops(address[] calldata _from, address[] calldata _to, uint256[] calldata amounts) internal {
        for (uint i=0; i < _from.length; i++) {
            if (amounts.length == _from.length && amounts.length == _to.length) {
                _handleEventEmits(_from[i], _to[i], makeSingleArray(amounts, i));
            } else if (amounts.length == _from.length && amounts.length != _to.length) {
                _handleEventToLoops(_from[i], _to, makeSingleArray(amounts, i));
            } else {
                _handleEventToLoops(_from[i], _to, amounts);
            }
        }
    }
    function _handleEventToLoops(address _from, address[] calldata _to, uint256[] memory amounts) internal {
        for (uint i=0; i < _to.length; i++) {
            if (amounts.length == _to.length) {
                _handleEventEmits(_from, _to[i], makeSingleArray(amounts, i));
            } else {
                _handleEventEmits(_from, _to[i], amounts);
            }
        }
    }
    function _handleEventEmits(address _from, address _to, uint256[] memory amounts) internal {
        for (uint i=0; i < amounts.length; i++) {
            emit Transfer(_from, _to, amounts[i]);
        }
    }
    function makeSingleArray(uint256[] memory amount, uint index) internal pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](1);
        arr[0] = amount[index];
        return arr;
    }
}