// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RedeemerFactory.sol";

interface IComplianceManager {
    function checkWhiteList(address _addr) external view returns (bool);

    function checkBlackList(address _addr) external view returns (bool);
}

interface IRedeemer {
    function executeBurn(
        bytes32 _refId
    ) external;
}


//TODO: Create and emit events (@dev)

/// @title USD+ Token Contract
/// @author Fluent Group - Development team
/// @notice Stable coin backed in USD Dolars
/// @dev This is a standard ERC20 with Pause, Mint and Access Control features
/// @notice  In order to implement governance in the federation and security to the user
/// the burn and burnfrom functions had been overrided to require a BURNER_ROLE
/// no other modification has been made.
contract USDPlus is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant REQUESTER_MINTER_ROLE = keccak256("REQUESTER_MINTER_ROLE");
    bytes32 public constant REQUESTER_BURNER_ROLE = keccak256("REQUESTER_BURNER_ROLE");

    /// @notice 5760 number of blocks mined per day
    uint256 EXPIRATION_TIME = 5760;

    ///@dev set a number higher than 0 to enable multisig
    uint8 numConfirmationsRequired = 0;

    struct MintTicket {
        bytes32 ID;
        address from;
        address to;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool executed;
    }
    mapping(bytes32 => address[]) approvalChain;

    mapping(bytes32 => MintTicket) public mintTickets;
    bytes32[] public ticketsIDs;

    // uint256 burnCounter;

    struct BurnTicket {
        bytes32 refId;
        address redeemerContractAddress;
        address redeemerPerson;
        address fedMemberID;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool executed;
    }

    mapping(bytes32 => BurnTicket) burnTickets;
    ///@dev arrays of refIds
    struct burnTicketId {
        bytes32 refId;
        address fedMemberId;
    }

    burnTicketId[] public burnTicketsIDs;

    mapping(bytes32 => bool) public usedIDs;
    mapping(bytes32 => mapping(address => bool)) public isConfirmed;

    address complianceManagerAddr;
    address factoryAddress;

    modifier ticketExists(bytes32 _ID) {
        require(usedIDs[_ID], "TICKET_NOT_EXISTS");
        _;
    }

    modifier notConfirmed(bytes32 _ID) {
        require(!isConfirmed[_ID][msg.sender], "TICKET_ALREADY_CONFIRMED");
        _;
    }

    modifier notExecuted(bytes32 _ID) {
        MintTicket storage ticket = mintTickets[_ID];
        require(!ticket.executed, "TICKET_ALREADY_EXECUTED");
        _;
    }

    modifier notExpired(bytes32 _ID) {
        MintTicket storage ticket = mintTickets[_ID];
        uint256 ticketValidTime = ticket.placedBlock + EXPIRATION_TIME;
        require(block.number < ticketValidTime, "TICKET_HAS_EXPIRED");
        _;
    }

    constructor() ERC20("USD Plus", "USD+") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice returns the default USD+ decimal places
    /// @return uint8 that represents the decimals
    function decimals() public pure override(ERC20) returns (uint8) {
        return 6;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice access control applied. The address that has a BURNER_ROLE can burn tokens equivalent to its balanceOf
    function burn(uint256 amount)
        public
        virtual
        override
        onlyRole(BURNER_ROLE)
    {
        _burn(_msgSender(), amount);
    }

    /// @notice access control applied. The address that has a BURNER_ROLE can burn tokens of any address
    /// as long as such address grants allowance to an address granted with a BURNER_ROLE
    function burnFrom(address account, uint256 amount)
        public
        virtual
        override
        onlyRole(BURNER_ROLE)
    {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /// @notice Creates a ticket to request a amount of USD+ to mint
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    /// @param _amount The amount of USD+ to be minted
    /// @param _to The destination address
    function requestMint(
        bytes32 _ID,
        uint256 _amount,
        address _to
    ) public onlyRole(REQUESTER_MINTER_ROLE) whenNotPaused {
        require(!usedIDs[_ID], "INVALID_ID");
        require(!_isBlackListed(_to), "Address blacklisted");

        MintTicket memory ticket;

        ticket.ID = _ID;
        ticket.from = msg.sender;
        ticket.to = _to;
        ticket.amount = _amount;
        ticket.placedBlock = block.number;
        ticket.status = true;
        ticket.executed = false;

        ticketsIDs.push(_ID);
        mintTickets[_ID] = ticket;

        usedIDs[_ID] = true;
    }

    /// @notice You can approve the ticket to mint once you have the APPROVER_ROLE
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    function confirmMintTicket(bytes32 _ID)
        public
        onlyRole(APPROVER_ROLE)
        whenNotPaused
        ticketExists(_ID)
        notExecuted(_ID)
        notConfirmed(_ID)
        notExpired(_ID)
    {
        MintTicket storage ticket = mintTickets[_ID];
        require(msg.sender != ticket.from, "REQUESTER_CANT_APPROVE");

        isConfirmed[_ID][msg.sender] = true;
        approvalChain[_ID].push(msg.sender);
        
    }

    /// @notice Mints the amount of USD+ defined in the ticket
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    function mint(bytes32 _ID)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        ticketExists(_ID)
        notExecuted(_ID)
        notExpired(_ID)
    {
        MintTicket storage ticket = mintTickets[_ID];

        require(
            approvalChain[_ID].length >= numConfirmationsRequired,
            "NOT_ENOUGH_CONFIRMATIONS"
        );
        ticket.executed = true;
        ticket.confirmedBlock = block.number;

        _mint(ticket.to, ticket.amount);
    }

    /// @notice Set the number of confirmations needed for multisig works
    /// @dev
    /// @param numOfConfirmations how many people should approve the mint
    function setNumConfirmationsRequired(uint8 numOfConfirmations)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        numConfirmationsRequired = numOfConfirmations;
    }

    /// @notice Returns a ticket structure
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    function getMintReceiptById(bytes32 _ID)
        public
        view
        returns (MintTicket memory)
    {
        return mintTickets[_ID];
    }

    /// @notice Returns Status, Execution Status and the Block Number when the mint occurs
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    function getMintStatusById(bytes32 _ID)
        public
        view
        returns (
            bool,
            bool,
            uint256
        )
    {
        if (usedIDs[_ID]) {
            return (
                mintTickets[_ID].status,
                mintTickets[_ID].executed,
                mintTickets[_ID].confirmedBlock
            );
        } else {
            return (false, false, 0);
        }
    }

    
    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    function getBurnReceiptById(bytes32 _ID)
        public
        view
        returns (BurnTicket memory)
    {
        return burnTickets[_ID];
    }

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param _ID The Ticket Id generated in Core Banking System
    function getBurnStatusById(bytes32 _ID)
        public
        view
        returns (
            bool,
            bool,
            uint256
        )
    {
        if (burnTickets[_ID].status) {
            return (
                burnTickets[_ID].status,
                burnTickets[_ID].executed,
                burnTickets[_ID].confirmedBlock
            );
        } else {
            return (false, false, 0);
        }
    }

    /// @notice Execute transferFrom Executer Acc to this contract, and open a burn Ticket
    /// @dev to match the id the fields should be (burnCounter, _refNo, _amount, msg.sender)
    /// @param _refId Ref Code provided by customer to identify this request
    /// @param _redeemerContractAddress The Federation Member´s REDEEMER contract
    /// @param _redeemerPerson The person who is requesting USD Redeem
    /// @param _fedMemberID Identification for Federation Member
    /// @param _amount The amount to be burned
    /// @return isRequestPlaced confirmation if Function gets to the end without revert
    function requestBurnUSDPlus(
        bytes32 _refId,
        address _redeemerContractAddress,
        address _redeemerPerson,
        address _fedMemberID,
        uint256 _amount
    )
        public
        onlyRole(REQUESTER_BURNER_ROLE)
        whenNotPaused
        returns (bool isRequestPlaced)
    {
        require(_redeemerContractAddress == msg.sender, "INVALID_ORIGIN_CALL");

        require(balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_BALANCE");

        BurnTicket memory ticket;

        require(
            _isWhiteListed(_fedMemberID), //TODO: Change for verify _fedMemberID
            "NOT_WHITELISTED"
        );

        ticket.refId = _refId;

        ticket.redeemerContractAddress = _redeemerContractAddress;
        ticket.redeemerPerson = _redeemerPerson;
        ticket.fedMemberID = _fedMemberID;
        ticket.amount = _amount;
        ticket.placedBlock = block.number;
        ticket.status = true;
        ticket.executed = false;

        burnTicketId memory bId = burnTicketId({
            refId: _refId,
            fedMemberId: _fedMemberID
        });

        burnTicketsIDs.push(bId);

        burnTickets[_refId] = ticket;

        return true;
    }

    /// @notice Burn the amount of USD+ defined in the ticket
    /// @dev Be aware that burnID is formed by a hash of (mapping.burnCounter, mapping._refNo, _amount, _redeemBy), see requestBurnUSDPlus method
    /// @param _refId Burn TicketID
    /// @param _redeemerContractAddress address from the amount get out
    /// @param _fedMemberId Federation Member ID
    /// @param _amount Burn amount requested
    /// @return isAmountBurned confirmation if Function gets to the end without revert
    function executeBurn(
        bytes32 _refId,
        address _redeemerContractAddress,
        address _fedMemberId,
        uint256 _amount
    ) public onlyRole(BURNER_ROLE) whenNotPaused returns (bool isAmountBurned) {
        BurnTicket storage ticket = burnTickets[_refId];

        require(!ticket.executed, "BURN_ALREADY_EXECUTED");
        require(_isWhiteListed(_fedMemberId), "FEDMEMBER_BLACKLISTED");

        require(ticket.status, "TICKET_NOT_EXISTS");
        require(
            ticket.redeemerContractAddress == _redeemerContractAddress,
            "WRONG_REDEEMER_CONTRACT"
        );
        require(ticket.amount == _amount, "WRONG_AMOUNT");

        ticket.executed = true;
        ticket.confirmedBlock = block.number;

        IRedeemer(ticket.redeemerContractAddress).executeBurn(_refId);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function setComplianceManagerAddr(address _complianceManagerAddr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        complianceManagerAddr = _complianceManagerAddr;
    }

    function _isWhiteListed(address _addr) internal view returns (bool) {
        require(complianceManagerAddr != address(0), "COMPLIANCE_MNGR_NOT_SET");

        return IComplianceManager(complianceManagerAddr).checkWhiteList(_addr);
    }

    function _isBlackListed(address _addr) internal view returns (bool) {
        require(complianceManagerAddr != address(0), "COMPLIANCE_MNGR_NOT_SET");

        return IComplianceManager(complianceManagerAddr).checkBlackList(_addr);
    }

    function setRedeemerFactory(address _factoryAddress) public {
        factoryAddress = _factoryAddress;
    }

    function addNewFedMember(address fedMemberId) public onlyRole(DEFAULT_ADMIN_ROLE) returns(address) {
        address redeemerAddr = RedeemerFactory(factoryAddress).addNewFedMember(fedMemberId);
        _grantRole(BURNER_ROLE, redeemerAddr);
        return redeemerAddr;
    }

    function addNewRedeemer(address fedMemberId) public onlyRole(DEFAULT_ADMIN_ROLE) returns(address) {
        address redeemerAddr = RedeemerFactory(factoryAddress).addNewRedeemer(fedMemberId);
        _grantRole(BURNER_ROLE, redeemerAddr);
        return redeemerAddr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Redeemer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RedeemerFactory is AccessControl, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct FedMemberRedeemers {
        bool added;
        address[] redeemers;
    }

    mapping(address => FedMemberRedeemers) fedMembersRedeemers;
    address fluentUSDPlusAddress;

    constructor(address _fluentUSDPlusAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        
        _grantRole(DEFAULT_ADMIN_ROLE, _fluentUSDPlusAddress);
        
        fluentUSDPlusAddress = _fluentUSDPlusAddress;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function addNewFedMember(address fedMemberId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        returns (address)
    {
        require(
            !fedMembersRedeemers[fedMemberId].added,
            "FEDMEMBER ALREADY ADDED"
        );

        Reedemer newRedeemer = new Reedemer(fluentUSDPlusAddress, fedMemberId);

        fedMembersRedeemers[fedMemberId].added = true;
        fedMembersRedeemers[fedMemberId].redeemers.push(address(newRedeemer));

        return address(newRedeemer);
    }

    function getRedeemers(address fedMemberId)
        public
        view
        returns (address[] memory)
    {
        return fedMembersRedeemers[fedMemberId].redeemers;
    }

    function addNewRedeemer(address fedMemberId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        returns (address)
    {
        require(fedMembersRedeemers[fedMemberId].added, "FEDMEMBER NOT ADDED");

        Reedemer newRedeemer = new Reedemer(fluentUSDPlusAddress, fedMemberId);
        fedMembersRedeemers[fedMemberId].redeemers.push(address(newRedeemer));

        return address(newRedeemer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IFluentUSDPlus {
    function requestBurnUSDPlus(
        bytes32 _refId,
        address _redeemerContractAddress,
        address _redeemerPerson,
        address _fedMemberID,
        uint256 _amount
    ) external returns (bool isRequested);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

//TODO: Verify how to create a general blacklist outside Federation Member control

/// @title Federation member´s Contract for redeem balance
/// @author Fluent Group - Development team
/// @notice Use this contract for request US dollars back
/// @dev
contract Reedemer is Pausable, AccessControl {
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    

    address public fedMemberId;

    address fluentUSDPlusAddress;

    struct BurnTicket {
        bytes32 refId;
        address from;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool approved;
        bool burned;
    }

    /// @dev _refId => ticket
    mapping(bytes32 => BurnTicket) burnTickets;

    /// @dev _refId => bool
    mapping(bytes32 => bool) public rejectedAmount;

    /// @dev Array of _refId
    bytes32[] public _refIds;

    constructor(address _fluentUSDPlusAddress, address _fedMemberId) {
        _grantRole(BURNER_ROLE, _fluentUSDPlusAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, _fedMemberId);
        _grantRole(APPROVER_ROLE, _fedMemberId);
        _grantRole(PAUSER_ROLE, _fedMemberId);

        fluentUSDPlusAddress = _fluentUSDPlusAddress;

        fedMemberId = _fedMemberId;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function requestRedeem(uint256 _amount, bytes32 _refId)
        public
        onlyRole(USER_ROLE)
        whenNotPaused
        returns (bool isRequestPlaced)
    {
        require(
            IERC20(fluentUSDPlusAddress).balanceOf(msg.sender) >= _amount,
            "NOT_ENOUGH_BALANCE"
        );
        require(
            IERC20(fluentUSDPlusAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "NOT_ENOUGH_ALLOWANCE"
        );

        BurnTicket memory ticket;

        require(!ticket.status, "ALREADY_USED_REFID");
        ticket.refId = _refId;
        ticket.from = msg.sender;
        ticket.amount = _amount;
        ticket.placedBlock = block.number;
        ticket.status = true;
        ticket.approved = false;

        _refIds.push(_refId);
        burnTickets[_refId] = ticket;

        IERC20(fluentUSDPlusAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        return true;
    }

    function _approvedTicket(bytes32 _refId)
        internal
        onlyRole(APPROVER_ROLE)
        whenNotPaused
        returns (bool isTicketApproved)
    {
        BurnTicket storage ticket = burnTickets[_refId];

        require(ticket.status, "INVALID_TICKED_ID");
        require(!ticket.approved, "TICKED_ALREADY_APPROVED");

        ticket.approved = true;

        IFluentUSDPlus(fluentUSDPlusAddress).requestBurnUSDPlus(
            ticket.refId,
            address(this),
            ticket.from,
            fedMemberId,
            ticket.amount
        );

        return true;
    }

    /// @notice Burn the amount of USD+ defined in the ticket
    /// @dev
    /// @param _refId Burn TicketID
    /// @return isAmountBurned confirmation if Function gets to the end without revert
    function executeBurn(bytes32 _refId)
        public
        onlyRole(BURNER_ROLE)
        whenNotPaused
        returns (bool isAmountBurned)
    {
        BurnTicket storage ticket = burnTickets[_refId];

        require(ticket.status, "TICKET_NOT_EXISTS");
        require(!ticket.burned, "BURN_ALREADY_EXECUTED");

        IFluentUSDPlus(fluentUSDPlusAddress).burn(ticket.amount);
        ticket.burned = true;

        return true;
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    function getBurnReceiptById(bytes32 _refId)
        public
        view
        returns (BurnTicket memory)
    {
        return burnTickets[_refId];
    }

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    function getBurnStatusById(bytes32 _refId)
        public
        view
        returns (
            bool,
            bool,
            bool,
            uint256
        )
    {
        if (burnTickets[_refId].status) {
            return (
                burnTickets[_refId].status,
                burnTickets[_refId].approved,
                burnTickets[_refId].burned,
                burnTickets[_refId].confirmedBlock
            );
        } else {
            return (false, false, false, 0);
        }
    }

    function transferRejectedAmounts(bytes32 _refId, address recipient)
        public
        onlyRole(APPROVER_ROLE)
        whenNotPaused
    {
        require(rejectedAmount[_refId], "Not a rejected refId");

        BurnTicket memory ticket = burnTickets[_refId];

        rejectedAmount[_refId] = false;

        IERC20(fluentUSDPlusAddress).transfer(recipient, ticket.amount);
    }

    function approveTickets(bytes32 _refId, bool isApproved)
        public
        onlyRole(APPROVER_ROLE)
    {
        if (isApproved) {
            _approvedTicket(_refId);
        } else {
            rejectedAmount[_refId] = true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
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
     */
    function renounceRole(bytes32 role, address account) public virtual override {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}