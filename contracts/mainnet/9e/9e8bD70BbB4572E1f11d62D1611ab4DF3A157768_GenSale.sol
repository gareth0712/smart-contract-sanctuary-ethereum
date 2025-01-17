// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IRegistrar} from "./interfaces/IRegistrar.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract GenSale is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  // zNS Registrar
  IRegistrar public zNSRegistrar;

  event RefundedEther(address buyer, uint256 amount, uint256 block);

  event SaleStarted(
    uint256 parentDomainId,
    uint256 salePrice,
    address zNSRegistrar,
    address sellerWallet,
    uint256 amountForSale,
    uint256 limitPerTransaction,
    bytes32 mintlistMerkleRoot,
    uint256 startingMetadataIndex,
    uint256 folderGroupID,
    uint256 block
  );

  event SaleStopped(uint256 block);

  event PauseStatusChanged(bool pauseStatus, uint256 block);

  event RegistrarChanged(address registrar, uint256 block);

  event MintlistMerkleRootChanged(bytes32 mintlistMerkleRoot, uint256 block);

  event PriceChanged(uint256 salePrice, uint256 block);

  event AmountForSaleChanged(uint256 amountForSale, uint256 block);

  event SellerWalletChanged(address seller, uint256 block);

  event LimitPerTransactionChanged(uint256 limitPerTransaction, uint256 block);

  event ParentDomainIdChanged(uint256 parentDomainId, uint256 block);

  event StartingMetadataIndexChanged(
    uint256 startingMetadataIndex,
    uint256 block
  );

  event FolderGroupIdChanged(uint256 folderGroupID, uint256 block);

  event DomainsPurchased(
    address indexed buyer,
    address indexed seller,
    uint256 salePrice,
    uint256 quantity,
    uint256 block
  );

  event GenSaleInit(
    uint256 parentDomainId,
    uint256 salePrice,
    address zNSRegistrar,
    address sellerWallet,
    uint256 amountForSale,
    uint256 limitPerTransaction,
    bytes32 mintlistMerkleRoot,
    uint256 startingMetadataIndex,
    uint256 folderGroupID,
    uint256 block
  );

  // The wallet to transfer proceeds to
  address public sellerWallet;

  // Indicating whether the sale has started or not
  bool public saleStarted;

  // The parent domain to mint sold domains under
  uint256 public parentDomainId;

  // Price of each domain to be sold
  uint256 public salePrice;

  // Number of domains sold so far
  uint256 public domainsSold;

  // The block number that a sale started on
  uint256 public saleStartBlock;

  // How many domains for sale during private sale
  uint256 public amountForSale;

  // The number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  uint256 public startingMetadataIndex;

  // The maximum number allowed to be purchased in a transaction during the private portion of this sale
  uint256 public limitPerTransaction;

  // The ID of the folder group that has been set up for this sale - needs to be initialized in advance
  uint256 public folderGroupID;

  // Merkle root data to verify on mintlist
  bytes32 public mintlistMerkleRoot;

  // Mapping to keep track of how many domains an account has purchased so far in both private and public sale periods
  // This is a running total and will apply equally to the sale regardless of the phase and it's limit.
  // e.g. 5 purchased in the private sale means only 4 more can be bought in the public sale if the public limit is 9
  // If you are not in the private sale, your limit for the public sale will be 9.
  mapping(address => uint256) public domainsPurchasedByAccount;

  function __GenSale_init(
    uint256 parentDomainId_,
    uint256 salePrice_,
    IRegistrar zNSRegistrar_,
    address sellerWallet_,
    uint256 amountForSale_,
    uint8 limitPerTransaction_,
    bytes32 merkleRoot_,
    uint256 startingMetadataIndex_,
    uint256 folderGroupID_
  ) public initializer {
    __Ownable_init();

    parentDomainId = parentDomainId_;
    salePrice = salePrice_;
    zNSRegistrar = zNSRegistrar_;
    sellerWallet = sellerWallet_;
    amountForSale = amountForSale_;
    limitPerTransaction = limitPerTransaction_;
    mintlistMerkleRoot = merkleRoot_;
    startingMetadataIndex = startingMetadataIndex_;
    folderGroupID = folderGroupID_;

    emit GenSaleInit(
      parentDomainId_,
      salePrice_,
      address(zNSRegistrar_),
      sellerWallet_,
      amountForSale_,
      limitPerTransaction_,
      merkleRoot_,
      startingMetadataIndex_,
      folderGroupID_,
      block.number
    );
  }

  // Set the registrar to be used when minting the domains
  function setRegistrar(IRegistrar zNSRegistrar_) external onlyOwner {
    require(
      address(zNSRegistrar_) != address(0),
      "Registrar cannot be address 0"
    );
    zNSRegistrar = zNSRegistrar_;
    emit RegistrarChanged(address(zNSRegistrar_), block.number);
  }

  // Start the sale if not started
  function startSale() external onlyOwner {
    require(!saleStarted, "Sale already started");
    saleStarted = true;
    // Identical to the GenSaleInit event but because it's possible
    // some values change between the call to init and starting the sale,
    // we emit again.
    emit SaleStarted(
      parentDomainId,
      salePrice,
      address(zNSRegistrar),
      sellerWallet,
      amountForSale,
      limitPerTransaction,
      mintlistMerkleRoot,
      startingMetadataIndex,
      folderGroupID,
      block.number
    );
  }

  // Stop the sale if started
  function stopSale() external onlyOwner {
    require(saleStarted, "Sale not started");
    saleStarted = false;
    emit SaleStopped(block.number);
  }

  // Update the data that acts as the merkle root
  function setMerkleRoot(bytes32 root) external onlyOwner {
    require(mintlistMerkleRoot != root, "same root");
    mintlistMerkleRoot = root;
    emit MintlistMerkleRootChanged(root, block.number);
  }

  // Pause a sale
  function setPauseStatus(bool pauseStatus) external onlyOwner {
    require(paused() != pauseStatus, "No state change");
    if (pauseStatus) {
      _pause();
    } else {
      _unpause();
    }
    emit PauseStatusChanged(pauseStatus, block.number);
  }

  // Set the price of this sale
  function setSalePrice(uint256 price) external onlyOwner {
    require(salePrice != price, "No price change");
    salePrice = price;
    emit PriceChanged(price, block.number);
  }

  // Set the amount of domains to be included in the sale
  function setAmountForSale(uint256 amountForSale_) external onlyOwner {
    require(amountForSale_ != amountForSale, "No state change");
    amountForSale = amountForSale_;
    emit AmountForSaleChanged(amountForSale_, block.number);
  }

  // Modify the address of the seller wallet
  function setSellerWallet(address wallet) external onlyOwner {
    require(wallet != sellerWallet, "Same Wallet");
    sellerWallet = wallet;
    emit SellerWalletChanged(wallet, block.number);
  }

  // Set the amount of domains able to be purchased per transaction
  function setLimitPerTransaction(uint256 limit) external onlyOwner {
    require(limitPerTransaction != limit, "Same limit");
    limitPerTransaction = limit;
    emit LimitPerTransactionChanged(limit, block.number);
  }

  // Modify parent domain ID of a domain
  function setParentDomainId(uint256 parentId) external onlyOwner {
    require(parentDomainId != parentId, "Same parent id");
    parentDomainId = parentId;
    emit ParentDomainIdChanged(parentId, block.number);
  }

  // Set the number with which to start the metadata index (e.g. number is 100, so indicies are 100, 101, ...)
  function setStartIndex(uint256 index) external onlyOwner {
    require(index != startingMetadataIndex, "Cannot set to the same index");
    require(!saleStarted, "Sale has already started");
    startingMetadataIndex = index;
    emit StartingMetadataIndexChanged(index, block.number);
  }

  // Set the folder group that the minted NFTs will reference. See registrar for more information.
  function setFolderGroupID(uint256 folderGroupID_) external onlyOwner {
    require(folderGroupID != folderGroupID_, "Cannot set to same folder group");
    require(!saleStarted, "Sale has already started");
    folderGroupID = folderGroupID_;
    emit FolderGroupIdChanged(folderGroupID_, block.number);
  }

  // Remove a domain from this sale
  function releaseDomain() external onlyOwner {
    zNSRegistrar.transferFrom(address(this), owner(), parentDomainId);
  }

  // Purchase `count` domains
  // Note the `purchaseLimit` you provide must be
  // less than or equal to what is in the mintlist
  function purchaseDomains(
    uint256 count,
    uint256 index,
    uint256 purchaseLimit,
    bytes32[] calldata merkleProof
  ) public payable nonReentrant {
    _canAccountPurchase(msg.sender, count, purchaseLimit);
    // Purchaser must still be on mintlist, but is only limited by the tx max.
    // The amount they've purchased is only checked in the claim sale portion
    _requireVariableMerkleProof(index, purchaseLimit, merkleProof);
    _purchaseDomains(count);
  }

  function _canAccountPurchase(
    address account,
    uint256 count,
    uint256 purchaseLimit
  ) internal view whenNotPaused {
    require(count > 0, "Zero purchase count");
    require(saleStarted, "Sale hasn't started or has ended");
    require(domainsSold < amountForSale, "No domains left for sale");
    require(msg.value >= salePrice * count, "Not enough funds in purchase");

    // For the first portion of the sale, users can claim Gens for free + gas for the tx require
    // They are restricted by the amount they are allowed to purchase
    // When the price is set, they are only restricted by the amount per transaction
    if (salePrice > 0) {
      // Private sale
      // require funds
      require(
        count <= limitPerTransaction,
        "Purchasing beyond transaction limit"
      );
    } else {
      // Claim sale
      // doesn't matter if they give funds? or mandate they don't?
      require(
        domainsPurchasedByAccount[account] + count <= purchaseLimit,
        "Purchasing beyond user limit"
      );
    }
  }

  function _purchaseDomains(uint256 count) internal {
    uint256 salePrice_ = salePrice;
    uint256 numPurchased = _reserveDomainsForPurchase(count);
    uint256 proceeds = salePrice_ * numPurchased;
    _sendPayment(proceeds);
    _mintDomains(numPurchased);
    emit DomainsPurchased(
      msg.sender,
      sellerWallet,
      salePrice_,
      numPurchased,
      block.number
    );
  }

  function _reserveDomainsForPurchase(
    uint256 count
  ) internal returns (uint256) {
    uint256 numPurchased = count;
    uint256 numForSale = amountForSale;
    // If we are trying to purchase more than is available, purchase the remainder
    if (domainsSold + count > numForSale) {
      numPurchased = numForSale - domainsSold;
    }
    domainsSold += numPurchased;

    // Update number of domains this account has purchased
    // This is done before minting domains or sending any eth to prevent
    // a re-entrance attack through a recieve() or a safe transfer callback
    domainsPurchasedByAccount[msg.sender] =
      domainsPurchasedByAccount[msg.sender] +
      numPurchased;

    return numPurchased;
  }

  // Transfer funds to the buying user, refunding if necessary
  function _sendPayment(uint256 proceeds) internal {
    payable(sellerWallet).transfer(proceeds);

    // Send refund if neceesary for any unpurchased domains
    uint256 refundValue = msg.value - proceeds;
    if (refundValue > 0) {
      payable(msg.sender).transfer(refundValue);
      emit RefundedEther(msg.sender, refundValue, block.number);
    }
  }

  function _mintDomains(uint256 numPurchased) internal {
    // Mint the domains after they have been purchased
    uint256 startingIndex = startingMetadataIndex + domainsSold - numPurchased;

    // The sale contract will be the minter and own them at this point
    zNSRegistrar.registerDomainInGroupBulk(
      parentDomainId, //parentId
      folderGroupID, //groupId
      0, //namingOffset
      startingIndex, //startingIndex
      startingIndex + numPurchased, //endingIndex
      sellerWallet, //minter
      0, //royaltyAmount
      msg.sender //sendTo
    );
  }

  function _requireVariableMerkleProof(
    uint256 index,
    uint256 quantity,
    bytes32[] calldata merkleProof
  ) internal view {
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, quantity));
    require(
      MerkleProofUpgradeable.verify(merkleProof, mintlistMerkleRoot, node),
      "Invalid Merkle Proof"
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IRegistrar {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function registerDomainAndSend(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256);

  function registerDomainInGroupBulk(
    uint256 parentId,
    uint256 groupId,
    uint256 namingOffset,
    uint256 startingIndex,
    uint256 endingIndex,
    address minter,
    uint256 royaltyAmount,
    address sendTo
  ) external;

  function createDomainGroup(string memory baseMetadataUri) external;

  function tokenByIndex(uint256 index) external view returns (uint256);

  function parentOf(uint256 id) external view returns (uint256);

  function ownerOf(uint256 id) external view returns (address);

  function numDomainGroups() external view returns (uint256);

  function isController(address account) external view returns (bool);

  function addController(address controller) external;

  function registerSubdomainContract(
    uint256 parentId,
    string memory label,
    address minter,
    string memory metadataUri,
    uint256 royaltyAmount,
    bool locked,
    address sendToUser
  ) external returns (uint256);

  function adminSetMetadataUri(uint256 id, string calldata uri) external;
}