pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


import "debond-erc3475/contracts/DebondERC3475.sol";


contract DebondBondTest is DebondERC3475 {

    constructor(address governanceAddress) DebondERC3475(governanceAddress) {}
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


interface IERC3475 {

    // STRUCT   
    /**
     * @dev structure allows the transfer of any given number of bonds from an address to another.
     * @title": "defning the title information",
     * @type": "explaining the type of the title information added",
    * @description": "little description about the information stored in  the bond",
     */
    struct Metadata {
        string title;
        string _type;
        string description;
        string[] values;
    }

    /**
     * @dev structure allows the transfer of any given number of bonds from an address to another.
     * @classId is the class id of bond.
     * @nonceId is the nonce id of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @_amount is the _amount of the bond, that will be transferred from "_from" address to "_to" address.
     */
    struct Transaction {
        uint256 classId;
        uint256 nonceId;
        uint256 _amount;
    }

    // WRITABLE

    /**
     * @dev allows the transfer of a bond from an address to another.
     * @param _from argument is the address of the holder whose balance about to decrees.
     * @param _to argument is the address of the recipient whose balance is about to increased.
     */
    function transferFrom(address _from, address _to, Transaction[] calldata _transaction) external;

    /**
     * @dev allows issuing of any number of bond types to an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _to is the address to which the bond will be issued.
     */
    function issue(address _to, Transaction[] calldata _transactions) external;

    /**
     * @dev allows redemption of any number of bond types from an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _from is the address _from which the bond will be redeemed.
     */
    function redeem(address _from, Transaction[] calldata _transactions) external;

    /**
     * @dev allows the transfer of any number of bond types from an address to another.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param _from argument is the address of the holder whose balance about to decrees.
     */
    function burn(address _from, Transaction[] calldata _transactions) external;

    /**
     * @dev Allows _spender to withdraw from your account multiple times, up to the _amount.
     * @notice If this function is called again it overwrites the current allowance with _amount.
     * @param _spender is the address the caller approve for his bonds
     */
    function approve(address _spender, Transaction[] calldata _transactions) external;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param _operator Address to add to the set of authorized operators
     * @param classId is the classId nonce of bond.
     * @param _approved "True" if the operator is approved, "False" to revoke approval
     */
    function setApprovalFor(address _operator, uint256 classId, bool _approved) external;

    // READABLES 

    /**
     * @dev Returns the total supply of the bond in question.
     */
    function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the redeemed supply of the bond in question.
     */
    function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the active supply of the bond in question.
     */
    function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the burned supply of the bond in question.
     */
    function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the balance of the giving bond classId and bond nonce.
     */
    function balanceOf(address _account, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
    * @dev Returns the values of given classId.
     * the metadata SHOULD follow a set of structure explained in eip-3475.md
     */
    function classValues(uint256 classId) external view returns (uint256[] memory);

    /**
    * @dev Returns the JSON metadata of the classes.
     * The metadata SHOULD follow a set of structure explained later in eip-3475.md
     */
    function classMetadata() external view returns (Metadata[] memory);

    /**
    * @dev Returns the values of given nonceId.
     * The metadata SHOULD follow a set of structure explained in eip-3475.md
     */
    function nonceValues(uint256 classId, uint256 nonceId) external view returns (uint256[] memory);

    /**
     * @dev Returns the JSON metadata of the nonces.
     * The metadata SHOULD follow a set of structure explained later in eip-3475.md
     */
    function nonceMetadata(uint256 classId) external view returns (Metadata[] memory);

    /**
     * @dev Returns the informations about the progress needed to redeem the bond
     * @notice Every bond contract can have their own logic concerning the progress definition.
     */
    function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining);

    /**
     * @notice Returns the _amount which spender is still allowed to withdraw from _owner.
     */
    function allowance(address _owner, address _spender, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
    * @notice Queries the approval status of an operator for a given owner.
     * Returns "True" if the operator is approved, "False" if not
     */
    function isApprovedFor(address _owner, address _operator, uint256 classId) external view returns (bool);

    // EVENTS

    /**
     * @notice MUST trigger when tokens are transferred, including zero value transfers.
     */
    event Transfer(address indexed _operator, address indexed _from, address indexed _to, Transaction[] _transactions);

    /**
     * @notice MUST trigger when tokens are issued
     */
    event Issue(address indexed _operator, address indexed _to, Transaction[] _transactions);

    /**
     * @notice MUST trigger when tokens are redeemed
     */
    event Redeem(address indexed _operator, address indexed _from, Transaction[] _transactions);

    /**
     * @notice MUST trigger when tokens are burned
     */
    event Burn(address indexed _operator, address indexed _from, Transaction[] _transactions);

    /**
     * @dev MUST emit when approval for a second party/operator address to manage all bonds from a classId given for an owner address is enabled or disabled (absence of an event assumes disabled).
     */
    event ApprovalFor(address indexed _owner, address indexed _operator, uint256 classId, bool _approved);

}

// SPDX-License-Identifier: apache 2.0

pragma solidity ^0.8.0;

import "../interfaces/IActivable.sol";
import "../interfaces/IGovernanceAddressUpdatable.sol";

contract GovernanceOwnable is IActivable, IGovernanceAddressUpdatable {

    constructor(address _governanceAddress) {
        governanceAddress = _governanceAddress;
        isActive = true;
    }

    address governanceAddress;
    bool isActive;

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Governance Restriction: Not allowed");
        _;
    }

    modifier _onlyIsActive() {
        require(isActive, "Contract Is Not Active");
        _;
    }

    function setIsActive(bool _isActive) external onlyGovernance {
        isActive = _isActive;
    }

    function setGovernanceAddress(address _governanceAddress) external onlyGovernance {
        require(_governanceAddress != address(0), "null address given");
        governanceAddress = _governanceAddress;
    }
}

// SPDX-License-Identifier: apache 2.0

pragma solidity ^0.8.0;

interface IGovernanceAddressUpdatable {

    function setGovernanceAddress(address _governanceAddress) external;
}

// SPDX-License-Identifier: apache 2.0

pragma solidity ^0.8.0;

interface IActivable {

    function setIsActive(bool _isActive) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IRedeemableBondCalculator {

    function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining);

    function getNonceFromDate(uint256 timestampDate) external view returns (uint256);

}

pragma solidity ^0.8.0;


// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import "erc3475/contracts/IERC3475.sol";



interface IDebondBond is IERC3475{

    function createNonce(uint256 classId, uint256 nonceId, uint256[] calldata values) external;

    function createClass(uint256 classId, string calldata symbol, uint256[] calldata values) external;

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external;

    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt);

    function classExists(uint256 classId) external view returns (bool);

    function nonceExists(uint256 classId, uint256 nonceId) external view returns (bool);

    function classLiquidity(uint256 classId) external view returns (uint256);

    function classLiquidityAtNonce(uint256 classId, uint256 nonceId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


import "./interfaces/IDebondBond.sol";
import "./interfaces/IRedeemableBondCalculator.sol";
import "debond-governance/contracts/utils/GovernanceOwnable.sol";


contract DebondERC3475 is IDebondBond, GovernanceOwnable {

    address bankAddress;

    /**
    * @notice this Struct is representing the Nonce properties as an object
    *         and can be retrieve by the nonceId (within a class)
    */
    struct Nonce {
        uint256 id;
        bool exists;
        uint256 _activeSupply;
        uint256 _burnedSupply;
        uint256 _redeemedSupply;
        uint256 classLiquidity;
        uint256[] values;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    /**
    * @notice this Struct is representing the Class properties as an object
    *         and can be retrieve by the classId
    */
    struct Class {
        uint256 id;
        bool exists;
        string symbol;
        uint256[] values;
        uint256 liquidity;
        mapping(address => mapping(uint256 => bool)) noncesPerAddress;
        mapping(address => uint256[]) noncesPerAddressArray;
        mapping(address => mapping(address => bool)) operatorApprovals;
        uint256[] nonceIds;
        mapping(uint256 => Nonce) nonces; // from nonceId given
        uint256 lastNonceIdCreated;
        uint256 lastNonceIdCreatedTimestamp;
    }

    mapping(uint256 => Class) internal classes; // from classId given
    string[] public classInfoDescriptions; // mapping with class.infos
    string[] public nonceInfoDescriptions; // mapping with nonce.infos
    mapping(address => mapping(uint256 => bool)) classesPerHolder;
    mapping(address => uint256[]) public classesPerHolderArray;

    constructor(address _governanceAddress) GovernanceOwnable(_governanceAddress) {}

    modifier onlyBank() {
        require(msg.sender == bankAddress, "DebondERC3475 Error: Not authorized");
        _;
    }

    //TODO onlyGovernance
    function setBankAddress(address _bankAddress) onlyGovernance external {
        require(_bankAddress != address(0), "DebondERC3475 Error: Address given is address(0)");
        bankAddress = _bankAddress;
    }


    // WRITE

    function issue(address to, Transaction[] calldata transactions) external override onlyBank {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            require(classes[classId].exists, "ERC3475: only issue bond that has been created");
            require(classes[classId].nonces[nonceId].exists, "ERC-3475: nonceId given not found!");
            require(to != address(0), "ERC3475: can't transfer to the zero address");
            _issue(to, classId, nonceId, amount);

            if (!classesPerHolder[to][classId]) {
                classesPerHolderArray[to].push(classId);
                classesPerHolder[to][classId] = true;
            }

            Class storage class = classes[classId];
            class.liquidity += amount;

            if (!class.noncesPerAddress[to][nonceId]) {
                class.noncesPerAddressArray[to].push(nonceId);
                class.noncesPerAddress[to][nonceId] = true;
            }

            Nonce storage nonce = class.nonces[nonceId];
            nonce.classLiquidity = class.liquidity + amount;
        }
        emit Issue(msg.sender, to, transactions);
    }

    function createClass(uint256 classId, string calldata _symbol, uint256[] calldata values) external onlyBank {
        require(!classExists(classId), "ERC3475: cannot create a class that already exists");
        Class storage class = classes[classId];
        class.id = classId;
        class.exists = true;
        class.symbol = _symbol;
        class.values = values;
    }

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external onlyBank {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        class.lastNonceIdCreated = nonceId;
        class.lastNonceIdCreatedTimestamp = createdAt;
    }

    function createNonce(uint256 classId, uint256 nonceId, uint256[] calldata values) external onlyBank {
        require(classExists(classId), "ERC3475: only issue bond that has been created");
        Class storage class = classes[classId];

        Nonce storage nonce = class.nonces[nonceId];
        require(!nonce.exists, "Error ERC-3475: nonceId exists!");

        nonce.id = nonceId;
        nonce.exists = true;
        nonce.values = values;
    }

    function getLastNonceCreated(uint classId) external view returns (uint nonceId, uint createdAt) {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        nonceId = class.lastNonceIdCreated;
        createdAt = class.lastNonceIdCreatedTimestamp;
        return (nonceId, createdAt);
    }

    function getNoncesPerAddress(address addr, uint256 classId) public view returns (uint256[] memory) {
        return classes[classId].noncesPerAddressArray[addr];
    }

    function batchActiveSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchActiveSupply;
        uint256[] memory nonces = classes[classId].nonceIds;
        // _lastBondNonces can be recovered from the last message of the nonceId
        // @drisky we can indeed
        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchActiveSupply += activeSupply(classId, nonces[i]);
        }
        return _batchActiveSupply;
    }

    function batchBurnedSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchBurnedSupply;
        uint256[] memory nonces = classes[classId].nonceIds;

        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchBurnedSupply += burnedSupply(classId, nonces[i]);
        }
        return _batchBurnedSupply;
    }

    function batchRedeemedSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchRedeemedSupply;
        uint256[] memory nonces = classes[classId].nonceIds;

        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchRedeemedSupply += redeemedSupply(classId, nonces[i]);
        }
        return _batchRedeemedSupply;
    }

    function batchTotalSupply(uint256 classId) public view returns (uint256) {
        uint256 _batchTotalSupply;
        uint256[] memory nonces = classes[classId].nonceIds;

        for (uint256 i = 0; i <= nonces.length; i++) {
            _batchTotalSupply += totalSupply(classId, nonces[i]);
        }
        return _batchTotalSupply;
    }

    function transferFrom(address from, address to, Transaction[] calldata transactions) public virtual override {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            require(msg.sender == from || isApprovedFor(from, msg.sender, classId), "ERC3475: caller is not owner nor approved");
            _transferFrom(from, to, classId, nonceId, amount);
        }

        emit Transfer(msg.sender, from, to, transactions);
    }

    function getProgress(uint256 classId, uint256 nonceId) public view returns (uint256 progressAchieved, uint256 progressRemaining) {
        return IRedeemableBondCalculator(bankAddress).getProgress(classId, nonceId);
    }


    function redeem(address from, Transaction[] calldata transactions) external override onlyBank {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            require(classes[classId].nonces[nonceId].exists, "ERC3475: given Nonce doesn't exist");
            require(from != address(0), "ERC3475: can't transfer to the zero address");
            (, uint256 progressRemaining) = getProgress(classId, nonceId);
            require(progressRemaining == 0, "Bond is not redeemable");
            _redeem(from, classId, nonceId, amount);
        }
        emit Redeem(msg.sender, from, transactions);
    }


    function burn(address from, Transaction[] calldata transactions) external override onlyBank {
        require(from != address(0), "ERC3475: can't transfer to the zero address");
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            _burn(from, classId, nonceId, amount);
        }
        emit Burn(msg.sender, from, transactions);
    }


    function approve(address spender, Transaction[] calldata transactions) external override {
        for (uint i; i < transactions.length; i++) {
            uint classId = transactions[i].classId;
            uint nonceId = transactions[i].nonceId;
            uint amount = transactions[i]._amount;
            classes[classId].nonces[nonceId].allowances[msg.sender][spender] = amount;
        }
    }


    function setApprovalFor(address operator, uint256 classId, bool approved) public override {
        classes[classId].operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, classId, approved);
    }

    // READS

    function classExists(uint256 classId) public view returns (bool) {
        return classes[classId].exists;
    }

    function nonceExists(uint256 classId, uint256 nonceId) public view returns (bool) {
        return classes[classId].nonces[nonceId].exists;
    }

    function classLiquidity(uint256 classId) external view returns (uint256) {
        return classes[classId].liquidity;
    }

    function classLiquidityAtNonce(uint256 classId, uint256 nonceId) external view returns (uint256) {
        require(nonceExists(classId, nonceId), "DebondERC3475 Error: nonce not found");
        return classes[classId].nonces[nonceId].classLiquidity;
    }

    function totalSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply + classes[classId].nonces[nonceId]._redeemedSupply;
    }


    function activeSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._activeSupply;
    }


    function burnedSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }


    function redeemedSupply(uint256 classId, uint256 nonceId) public override view returns (uint256) {
        return classes[classId].nonces[nonceId]._burnedSupply;
    }


    function balanceOf(address account, uint256 classId, uint256 nonceId) public override view returns (uint256) {
        require(account != address(0), "ERC3475: balance query for the zero address");

        return classes[classId].nonces[nonceId].balances[account];
    }

    function classValues(uint256 classId) public view override returns (uint256[] memory) {
        return classes[classId].values;
    }


    function nonceValues(uint256 classId, uint256 nonceId) public view override returns (uint256[] memory) {
        return classes[classId].nonces[nonceId].values;
    }

    function classMetadata() external view returns (Metadata[] memory m) {
        string[] memory s = new string[](1);
        m[0] = Metadata("", "", "", s);
    }

    function nonceMetadata(uint256 classId) external view returns (Metadata[] memory m) {
        string[] memory s = new string[](1);
        m[0] = Metadata("", "", "", s);
    }

    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256) {
        return classes[classId].nonces[nonceId].allowances[owner][spender];
    }


    function isApprovedFor(address owner, address operator, uint256 classId) public view virtual override returns (bool) {
        return classes[classId].operatorApprovals[owner][operator];
    }

    function _transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(from != address(0), "ERC3475: can't transfer from the zero address");
        require(to != address(0), "ERC3475: can't transfer to the zero address");
        require(classes[classId].nonces[nonceId].balances[from] >= amount, "ERC3475: not enough bond to transfer");
        _transfer(from, to, classId, nonceId, amount);
    }

    function _transfer(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(from != to, "ERC3475: can't transfer to the same address");
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId].balances[to] += amount;
    }

    function _issue(address to, uint256 classId, uint256 nonceId, uint256 amount) internal {
        classes[classId].nonces[nonceId].balances[to] += amount;
        classes[classId].nonces[nonceId]._activeSupply += amount;
    }

    function _redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._redeemedSupply += amount;
    }

    function _burn(address from, uint256 classId, uint256 nonceId, uint256 amount) internal {
        require(classes[classId].nonces[nonceId].balances[from] >= amount);
        classes[classId].nonces[nonceId].balances[from] -= amount;
        classes[classId].nonces[nonceId]._activeSupply -= amount;
        classes[classId].nonces[nonceId]._burnedSupply += amount;
    }
}