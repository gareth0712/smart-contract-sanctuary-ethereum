// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./OwnableStorage.sol";
import "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events, Context {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(_msgSender() == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(_msgSender(), account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AccessControlStorage.sol";
import "./IAccessControlEvents.sol";

abstract contract AccessControlInternal is Context, IAccessControlEvents {
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 role, address account) internal view virtual returns (bool) {
        return AccessControlStorage.layout().roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function _getRoleAdmin(bytes32 role) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function _renounceRole(bytes32 role, address account) internal virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!_hasRole(role, account)) {
            AccessControlStorage.layout().roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (_hasRole(role, account)) {
            AccessControlStorage.layout().roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library AccessControlStorage {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.AccessControl");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlEvents {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSalesInternal.sol";

interface ITieredSales is ITieredSalesInternal {
    function onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (bool);

    function eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (uint256);

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable;

    function remainingForTier(uint256 tierId) external view returns (uint256);

    function walletMintedByTier(uint256 tierId, address wallet) external view returns (uint256);

    function tierMints(uint256 tierId) external view returns (uint256);

    function totalReserved() external view returns (uint256);

    function reservedMints() external view returns (uint256);

    function tiers(uint256 tierId) external view returns (Tier memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITieredSalesInternal {
    struct Tier {
        uint256 start;
        uint256 end;
        address currency;
        uint256 price;
        uint256 maxPerWallet;
        bytes32 merkleRoot;
        uint256 reserved;
        uint256 maxAllocation;
    }

    event TierSale(uint256 indexed tierId, address indexed operator, address indexed minter, uint256 count);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITieredSalesRoleBased {
    function mintByTierByRole(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSales.sol";
import "./TieredSalesInternal.sol";

/**
 * @title Abstract sales mechanism for any asset (e.g NFTs) with multiple tiered pricing, allowlist and allocation plans.
 */
abstract contract TieredSales is ITieredSales, TieredSalesInternal {
    function onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) public view virtual returns (bool) {
        return super._onTierAllowlist(tierId, minter, maxAllowance, proof);
    }

    function eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) public view virtual returns (uint256 maxMintable) {
        return super._eligibleForTier(tierId, minter, maxAllowance, proof);
    }

    function remainingForTier(uint256 tierId) public view virtual returns (uint256) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        uint256 availableSupply = _availableSupplyForTier(tierId);
        uint256 availableAllocation = l.tiers[tierId].maxAllocation - l.tierMints[tierId];

        if (availableSupply < availableAllocation) {
            return availableSupply;
        } else {
            return availableAllocation;
        }
    }

    function walletMintedByTier(uint256 tierId, address wallet) public view virtual returns (uint256) {
        return TieredSalesStorage.layout().walletMinted[tierId][wallet];
    }

    function tierMints(uint256 tierId) public view virtual returns (uint256) {
        return TieredSalesStorage.layout().tierMints[tierId];
    }

    function totalReserved() external view virtual returns (uint256) {
        return TieredSalesStorage.layout().totalReserved;
    }

    function reservedMints() external view virtual returns (uint256) {
        return TieredSalesStorage.layout().reservedMints;
    }

    function tiers(uint256 tierId) external view virtual returns (Tier memory) {
        return TieredSalesStorage.layout().tiers[tierId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITieredSalesInternal.sol";
import "./TieredSalesStorage.sol";

import "../../access/ownable/OwnableInternal.sol";

/**
 * @title Sales mechanism for NFTs with multiple tiered pricing, allowlist and allocation plans
 */
abstract contract TieredSalesInternal is ITieredSalesInternal, Context, OwnableInternal {
    using TieredSalesStorage for TieredSalesStorage.Layout;

    function _configureTiering(uint256 tierId, Tier calldata tier) internal virtual {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(tier.maxAllocation >= l.tierMints[tierId], "LOWER_THAN_MINTED");

        if (l.tiers[tierId].reserved > 0) {
            require(tier.reserved >= l.tierMints[tierId], "LOW_RESERVE_AMOUNT");
        }

        if (l.tierMints[tierId] > 0) {
            require(tier.maxPerWallet >= l.tiers[tierId].maxPerWallet, "LOW_MAX_PER_WALLET");
        }

        l.totalReserved -= l.tiers[tierId].reserved;
        l.tiers[tierId] = tier;
        l.totalReserved += tier.reserved;
    }

    function _configureTiering(uint256[] calldata _tierIds, Tier[] calldata _tiers) internal virtual {
        for (uint256 i = 0; i < _tierIds.length; i++) {
            _configureTiering(_tierIds[i], _tiers[i]);
        }
    }

    function _onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal view virtual returns (bool) {
        return
            MerkleProof.verify(
                proof,
                TieredSalesStorage.layout().tiers[tierId].merkleRoot,
                _generateMerkleLeaf(minter, maxAllowance)
            );
    }

    function _eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal view virtual returns (uint256 maxMintable) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(l.tiers[tierId].maxPerWallet > 0, "NOT_EXISTS");
        require(block.timestamp >= l.tiers[tierId].start, "NOT_STARTED");
        require(block.timestamp <= l.tiers[tierId].end, "ALREADY_ENDED");

        maxMintable = l.tiers[tierId].maxPerWallet - l.walletMinted[tierId][minter];

        if (l.tiers[tierId].merkleRoot != bytes32(0)) {
            require(l.walletMinted[tierId][minter] < maxAllowance, "MAXED_ALLOWANCE");
            require(_onTierAllowlist(tierId, minter, maxAllowance, proof), "NOT_ALLOWLISTED");

            uint256 remainingAllowance = maxAllowance - l.walletMinted[tierId][minter];

            if (maxMintable > remainingAllowance) {
                maxMintable = remainingAllowance;
            }
        }
    }

    function _availableSupplyForTier(uint256 tierId) internal view virtual returns (uint256 remaining) {
        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        // Substract all the remaining reserved spots from the total remaining supply...
        remaining = _remainingSupply(tierId) - (l.totalReserved - l.reservedMints);

        // If this tier has reserved spots, add remaining spots back to result...
        if (l.tiers[tierId].reserved > 0) {
            remaining += (l.tiers[tierId].reserved - l.tierMints[tierId]);
        }
    }

    function _executeSale(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal virtual {
        address minter = _msgSender();

        uint256 maxMintable = _eligibleForTier(tierId, minter, maxAllowance, proof);

        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(count <= maxMintable, "EXCEEDS_MAX");
        require(count <= _availableSupplyForTier(tierId), "EXCEEDS_SUPPLY");
        require(count + l.tierMints[tierId] <= l.tiers[tierId].maxAllocation, "EXCEEDS_ALLOCATION");

        if (l.tiers[tierId].currency == address(0)) {
            require(l.tiers[tierId].price * count <= msg.value, "INSUFFICIENT_AMOUNT");
        } else {
            IERC20(l.tiers[tierId].currency).transferFrom(minter, address(this), l.tiers[tierId].price * count);
        }

        l.walletMinted[tierId][minter] += count;
        l.tierMints[tierId] += count;

        if (l.tiers[tierId].reserved > 0) {
            l.reservedMints += count;
        }

        emit TierSale(tierId, minter, minter, count);
    }

    function _executeSalePrivileged(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) internal virtual {
        uint256 maxMintable = _eligibleForTier(tierId, minter, maxAllowance, proof);

        TieredSalesStorage.Layout storage l = TieredSalesStorage.layout();

        require(count <= maxMintable, "EXCEEDS_MAX");
        require(count <= _availableSupplyForTier(tierId), "EXCEEDS_SUPPLY");
        require(count + l.tierMints[tierId] <= l.tiers[tierId].maxAllocation, "EXCEEDS_ALLOCATION");

        l.walletMinted[tierId][minter] += count;
        l.tierMints[tierId] += count;

        if (l.tiers[tierId].reserved > 0) {
            l.reservedMints += count;
        }

        emit TierSale(tierId, _msgSender(), minter, count);
    }

    function _remainingSupply(
        uint256 /*tierId*/
    ) internal view virtual returns (uint256) {
        // By default assume supply is unlimited (that means reserving allocation for tiers is irrelevant)
        return type(uint256).max;
    }

    /* PRIVATE */

    function _generateMerkleLeaf(address account, uint256 maxAllowance) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, maxAllowance));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSales.sol";

library TieredSalesStorage {
    struct Layout {
        uint256 totalReserved;
        uint256 reservedMints;
        mapping(uint256 => ITieredSales.Tier) tiers;
        mapping(uint256 => uint256) tierMints;
        mapping(uint256 => mapping(address => uint256)) walletMinted;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.TieredSales");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

import "./ERC2771ContextStorage.sol";

abstract contract ERC2771ContextInternal is Context {
    function _isTrustedForwarder(address operator) internal view returns (bool) {
        return ERC2771ContextStorage.layout().trustedForwarder == operator;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC2771ContextStorage {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openzeppelin.contracts.storage.ERC2771Context");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC1155} that allows a specific role to mint tokens.
 */
interface IERC1155MintableRoleBased {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have MINTER_ROLE.
     */
    function mintByRole(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintByRole(
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC1155TieredSalesStorage {
    struct Layout {
        mapping(uint256 => uint256) tierToTokenId;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC1155TieredSales");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows a specific role to mint tokens.
 */
interface IERC721MintableRoleBased {
    /**
     * @dev Mints `amount` new tokens for `to`.
     */
    function mintByRole(address to, uint256 amount) external;

    /**
     * @dev Mints multiple `amount`s of new tokens for every single address in `tos`.
     */
    function mintByRole(address[] calldata tos, uint256[] calldata amounts) external;

    /**
     * @dev Mint a new token with a dedicated tokenURI.
     */
    function mintByRole(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@flair-sdk/contracts/access/ownable/OwnableInternal.sol";
import "@flair-sdk/contracts/finance/sales/TieredSales.sol";
import "@flair-sdk/contracts/finance/sales/ITieredSalesRoleBased.sol";
import "@flair-sdk/contracts/metatx/ERC2771ContextInternal.sol";
import "@flair-sdk/contracts/access/roles/AccessControlInternal.sol";
import "@flair-sdk/contracts/token/ERC721/facets/minting/IERC721MintableRoleBased.sol";
import "@flair-sdk/contracts/token/ERC1155/facets/minting/IERC1155MintableRoleBased.sol";
import "@flair-sdk/contracts/token/ERC1155/facets/sales/ERC1155TieredSalesStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // TODO replace with diamond version

/**
 * @title My Custom Tiered Sales
 * @notice This is developed in-house to provide custom sales mechanism for our custom project.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces ITieredSales, ITieredSalesRoleBased
 */
contract MyCustomTieredSales is
    ITieredSalesRoleBased,
    OwnableInternal,
    TieredSales,
    ERC2771ContextInternal,
    AccessControlInternal,
    ReentrancyGuard
{
    using TieredSalesStorage for TieredSalesStorage.Layout;
    using ERC1155TieredSalesStorage for ERC1155TieredSalesStorage.Layout;

    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");
    bytes32 internal constant STORAGE_SLOT = keccak256("v1.my-amazing-team.contracts.storage.MyCustomTieredSales");

    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * (1) Define state variables
     *
     * We must put all contract "state" variables in the Layout struct.
     * This storage pattern enables modularization using the EIP-2325 Diamond Standard.
     *
     *  To learn more about this pattern, see the following resources:
     *  - https://eips.ethereum.org/EIPS/eip-2325
     *  - https://eip2535diamonds.substack.com
     */
    struct Layout {
        address targetERC721ContractAddress;
        address targetERC1155ContractAddress;
    }

    /**
     * (2) Define custom functions
     *
     * You can put privileged functions (using Ownable or role-based AccessControl) here.
     */
    function setTargetTokens(address erc721ContractAddress, address erc1155ContractAddress) external onlyOwner {
        layout().targetERC721ContractAddress = erc721ContractAddress;
        layout().targetERC1155ContractAddress = erc1155ContractAddress;
    }

    /**
     * (3) Customize the "mintByTier" method.
     *
     * This custom facet contract extends TieredSales, which needs us to define what sales logic we want
     * when users are minting a specific tier.
     */
    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable override nonReentrant {
        // This call checks if user has enough allowance for the tier, checks the proof, records the minted amount,
        // and ensures the payment is correct.
        //
        // If this call is not reverted you can safely provide the _msgSender() with any assets you want for the sale.
        // For example you can mint "count" NFTs to the _msgSender(), or send "count" amount of an ERC20 tokens, etc.
        super._executeSale(tierId, count, maxAllowance, proof);

        // This is the custom logic for our project, which in this case is to mint from ERC721 and ERC1155 contracts.
        IERC721MintableRoleBased(layout().targetERC721ContractAddress).mintByRole(_msgSender(), count);
        IERC1155MintableRoleBased(layout().targetERC1155ContractAddress).mintByRole(
            _msgSender(),
            ERC1155TieredSalesStorage.layout().tierToTokenId[tierId],
            count,
            ""
        );
    }

    /**
     * (4) Customize the "mintByTierByRole" method.
     *
     * This function mints tokens based on tier and role. We need this function when minting an NFT
     * with credit card or crypto payment.
     */
    function mintByTierByRole(
        address minter,
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable virtual nonReentrant onlyRole(MERCHANT_ROLE) {
        super._executeSalePrivileged(minter, tierId, count, maxAllowance, proof);

        IERC721MintableRoleBased(layout().targetERC721ContractAddress).mintByRole(_msgSender(), count);
        IERC1155MintableRoleBased(layout().targetERC1155ContractAddress).mintByRole(
            _msgSender(),
            ERC1155TieredSalesStorage.layout().tierToTokenId[tierId],
            count,
            ""
        );
    }
}