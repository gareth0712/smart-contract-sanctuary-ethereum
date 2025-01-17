/*

                                                                   
                                                                    [email protected]&Y.                                                                  
                                                                   ^[email protected]@#&G^                                                                 
                                                                  7&@@@##&B!                                                                
                                                                 [email protected]@@@@#####J.                                                              
                                                               :[email protected]@@@@@#####&P:                                                             
                                                              !#@@@@@@@######&B!                                                            
                                                             [email protected]@@@@@@@@#########J                                                           
                                                           :[email protected]@@@@@@@@@#########&P:                                                         
                                                          ~#@@@@@@@@@@@##########&B~                                                        
                                                         [email protected]@@@@@@@@@@@@#############?                                                       
                                                       :[email protected]@@@@@@@@@@@@@#############&5:                                                     
                                                      :[email protected]@@@@@@@@@@@@@@##############&G:                                                    
                                                       7B&&&@@@@@@@@@@@###########BBBG7                                                     
                                                        ^P&####&&&@@@@@######BBBBGGBP^                                                      
                                                         .Y#########&&&#BBBBGGGGGBBY.                                                       
                                                           7#&#########BGGGGGGGGBG7                                                         
                                                            ^G&########BGGGGGGBBP~                                                          
                                                             .Y&#######BGGGGGBBY:                                                           
                                                               7#######BGGGGBB?                                                             
                                                                ~G&####BGGBBP~                                                              
                                                                 .5&###BGBB5:                                                               
                                                                   ?###BBB?                                                                 
                                                                    ~B#BG!                                                                  
                                                                     :P5:                                                                   
           .^!J5PGGGGP5J!.                                             .                                                                    
        ^?G##B5J7~^^::[email protected]@#^                                                                                                                 
     :[email protected]~!PY?:    ^#@@&^                                                               ::.                                               
   :[email protected]@G#J  [email protected]@@G  .?&@@G^                                                               [email protected]&#~                                              
  7&@#~ :: [email protected]@@B::?#@&P~                                                                 [email protected]@&^                                              
  [email protected]&:   [email protected]@@B?5&&P7:                                                                   .^~^                                               
  :?7   ^[email protected]@@@@@@#PJ!.      :!?YJ?~.JJ7.   !JJ7:    :YP!    ^7JYJ7.!YJ~    7YJ^  ^?JJ^  YG5!      .~?YY?!.?Y?^   .JJ7:   :7Y5J:   .!JPP5P5^ 
       7&@@BJ?!^::[email protected]@&?   ~P&@#J~!#[email protected]@@Y   [email protected]@@#:    [email protected] [email protected]@P!^Y##@@@^   [email protected]@[email protected]@@7 [email protected]@@#.   :Y#@@5!~GB&@@#.  [email protected]@@5 ~5P#@@@~  ?#@B?^[email protected]
[email protected]@@5.  .^^ [email protected]@@# [email protected]@@Y.   [email protected]@@&^  .#@@@&:   [email protected]^~#@@#~   [email protected]@@@5   [email protected]@@@[email protected]@J ^#@@@7   ?&@@G:   [email protected]@@@?  :#@@&YPP!Y&@@Y  [email protected]@#:  [email protected]
[email protected]@&J^[email protected]@@&[email protected]@@7    [email protected]@@#^   [email protected]@@@5    [email protected][email protected]@@G:   [email protected]@@Y   [email protected]@@&? [email protected]@5 :#@@&7   [email protected]@@5    :#@@@7  [email protected]@@&G! [email protected]@@5   ^&@@#?:~^   
     J&@#557^  :[email protected]@@G~ [email protected]@@?    !&@@B:  [email protected]@@@&^  :P&!:&@@#:   [email protected]@@J  .?&@@#~  :?J^:[email protected]@&!  :[email protected]@@P    :[email protected]@&!  :[email protected]@@#7  [email protected]@@Y   7BP~J#@#Y:   
     ^BB!.   [email protected]@@G!  .#@@G   :[email protected]@@G. ~PBY&@@@Y .?#G^ [email protected]@@!   [email protected]@@? .?#@@@B^       [email protected]@&~ ^5B&@@&:  .?#@@&~ :Y&@@@Y.  [email protected]@@5  7GG7~~  [email protected]@5   
    .#@~.^75#@@BJ^     [email protected]@[email protected]@@Y?GB?..&@@@J?GP~   ~&@@[email protected]@&[email protected]@@B:       .#@@B7PBY:[email protected]@&7!YGP&@@G7P&@@@B~    [email protected]@@?JBG!:[email protected]?.^[email protected]^   
     ~JY5PG5J!:         !J5YJ!. !Y55J~    ~Y5Y?!:      :?Y5Y?^ .?55Y7::5P5^         :?Y5Y!.   ^J55J7: ^J55Y!~Y5?.     .75P5J^  :G#PPGY~       

*/

//SPDX-License-Identifier: MIT
//Creator: Sergey Kassil / 24acht GmbH

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./GenesisNFBToken.sol";


/**
@title Non-Fungible Bavarians ERC721 Contract 
@author Sergey K. / 24acht GmbH
@notice This Contract provides all the basic functionality for the Non-Fungible Bavarians.
@notice That includes Minting, Mint-Batches, Access Control, IPFS-URI, ID-Generation, etc.
@dev Contract build on ERC721 openzepplin implementation, OZ's Pausbale for regualting mint-on/off-turning and OZ's Counters for secure token count increments.
*/
contract NonFungibleBavarians is ERC721, Pausable {
  using Counters for Counters.Counter;

  //The maximal amount of mintable tokens - constant and thus unchangeable
  uint16 constant MAX_SUPPLY = 1100;

  //Amount of Genesis NFB Owners
  uint8 constant NUM_GNFB_OWNERS = 11;

  //Secure counter for the tokens' IDs
  Counters.Counter private _currentTokenId;
  
  //Storage space for Genesis NFB owners-array deep copy
  address[NUM_GNFB_OWNERS] public genesisOwners;

  //NFB project founders' (Björn, Manuel, Chris) team wallet address
  address constant _foundersTeamWallet = 0x41A777dC5b6530583413bd9B27C85334F5541cC4;

  //Address of the GenesisNFBToken smart contract
  address public genesisTokenAddress = 0x019dCCfF6cf26Bd6dDd21C82253770841dAC7A2b;

  //Reference to deployed Genesis NFB smart contract, for accessing gNFB owners
  GenesisNFBToken private _genesisContract = GenesisNFBToken(genesisTokenAddress);

  //Initial NFB Mint price in ETH - setter avaliable for founders
  uint256 public mintPrice = 0.25 ether;

  //Inital mint batch of tokens - must be resetted once it reaches 0, by a founder, to reactivate minting. 
  uint16 public currentMintBatch = 100;

  //Restriction on how many mints are allowed per wallet
  uint8 private _mintsPerWallet = 3;

  

  /**
  @dev start token count at 1
  @dev pass nonce value when deploying
   */
  constructor() ERC721("Non-Fungible Bavarians", "NFB") {
    _currentTokenId.increment();
    genesisOwners = getGenesisOwners();
  }

  /**
  @notice Check if any address holds an NFB or a Genesis NFB
   */
  function isTokenOwner(address toBeChecked) public view returns(bool) {
    for(uint8 i = 0; i < NUM_GNFB_OWNERS; i++) {
      if(toBeChecked == genesisOwners[i]) {
        return true;
      }
    }
    return balanceOf(toBeChecked) > 0;
  }


  /**
  @notice functions with the onlyFounder modifier can be only accessed by the projects founders
  @notice founders can either access the function via their gNFB-holding wallet or via their shared multi-sig
   */
  modifier onlyFounder() {
    require(msg.sender == _foundersTeamWallet 
    || msg.sender == genesisOwners[0] 
    || msg.sender == genesisOwners[1] 
    || msg.sender == genesisOwners[2],
    "Only the tokens original founders can call this function!");
    _;
  }



  /**
  @notice functiion that provides an array of the genesis NFB owners 
  @dev a call like "gNFBOwners = _genesisContract.owners();" doesn't work, due to technical reasons
  @dev therefore the elements must be copied one by one
  */
  function getGenesisOwners() public view returns(address[11] memory) {
    address[NUM_GNFB_OWNERS] memory gNFBOwners;
    for(uint8 i = 0; i < NUM_GNFB_OWNERS; i++) {
      gNFBOwners[i] = _genesisContract.owners(i);
    }
    return gNFBOwners;
  }

  /**
  @notice New tokens can be minted with this function. The payed price gets immediately tranferred to the founders team wallet.
  @dev Only callable when the mint batch is higher than  0 (else the contract gets paused and a new batch must be set in setNewMintBatch() )
  @dev Checks for correct amount payed, performs every write ops before interacting with the caller (_mint)
   */
  function mint() external payable whenNotPaused {
    require(msg.value >= mintPrice, "Not enough ETH payed for minting!");
    require(balanceOf(msg.sender) < _mintsPerWallet, "You cannot mint more than 3 NFBs");
    
    currentMintBatch--;

    if(currentMintBatch == 0) {
      _pause();
    }

    uint256 tokenId = _currentTokenId.current();
    _currentTokenId.increment();

    (bool success,) = _foundersTeamWallet.call{value: msg.value}("");
    require(success, "Failed to receive funds"); 

    _mint(msg.sender, tokenId);
  } 

  /**
  @notice This function is to be used, when a new batch of mintable tokens shall be issued
  */
  function setNewMintBatch(uint16 newBatch, uint256 newMintPriceInWei) external onlyFounder whenPaused { 
    require(newBatch > 0, "The new batch must have a minimum value of 1");

    uint256 tokensIssued = _currentTokenId.current();
    require(tokensIssued + newBatch <= MAX_SUPPLY, "The new batch must not exceed the maximum amount of mintable tokens!");

    if(newMintPriceInWei > 0) {
      setNewMintPrice(newMintPriceInWei);
    }
    
    currentMintBatch = newBatch;
    _unpause();
  }

  /**
  @notice mint price setter - can be used anytime
   */
  function setNewMintPrice(uint256 newMintPriceInWei) public onlyFounder {
    require(newMintPriceInWei > 0, "The mint price must not be zero!");
    mintPrice = newMintPriceInWei;
  }

  function pauseMinting() external onlyFounder {
    _pause();
  }

  function unpauseMinting() external onlyFounder {
    _unpause();
  }


  /** 
  @dev define base uri, which will later be used to create the full uri
  **/
  function _baseURI() override internal view returns(string memory) {
    return "ipfs://bafybeicydjp3xkmiv6pq34wkcl637n5slhy2kchw4y4guh6jz4wh6gstfu/";
  }

  /**
  * @dev Returns an URI for a given token ID
  */
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(tokenId),
        ".json"
    ));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/*

                                                                   
                                                                    [email protected]&Y.                                                                  
                                                                   ^[email protected]@#&G^                                                                 
                                                                  7&@@@##&B!                                                                
                                                                 [email protected]@@@@#####J.                                                              
                                                               :[email protected]@@@@@#####&P:                                                             
                                                              !#@@@@@@@######&B!                                                            
                                                             [email protected]@@@@@@@@#########J                                                           
                                                           :[email protected]@@@@@@@@@#########&P:                                                         
                                                          ~#@@@@@@@@@@@##########&B~                                                        
                                                         [email protected]@@@@@@@@@@@@#############?                                                       
                                                       :[email protected]@@@@@@@@@@@@@#############&5:                                                     
                                                      :[email protected]@@@@@@@@@@@@@@##############&G:                                                    
                                                       7B&&&@@@@@@@@@@@###########BBBG7                                                     
                                                        ^P&####&&&@@@@@######BBBBGGBP^                                                      
                                                         .Y#########&&&#BBBBGGGGGBBY.                                                       
                                                           7#&#########BGGGGGGGGBG7                                                         
                                                            ^G&########BGGGGGGBBP~                                                          
                                                             .Y&#######BGGGGGBBY:                                                           
                                                               7#######BGGGGBB?                                                             
                                                                ~G&####BGGBBP~                                                              
                                                                 .5&###BGBB5:                                                               
                                                                   ?###BBB?                                                                 
                                                                    ~B#BG!                                                                  
                                                                     :P5:                                                                   
           .^!J5PGGGGP5J!.                                             .                                                                    
        ^?G##B5J7~^^::[email protected]@#^                                                                                                                 
     :[email protected]~!PY?:    ^#@@&^                                                               ::.                                               
   :[email protected]@G#J  [email protected]@@G  .?&@@G^                                                               [email protected]&#~                                              
  7&@#~ :: [email protected]@@B::?#@&P~                                                                 [email protected]@&^                                              
  [email protected]&:   [email protected]@@B?5&&P7:                                                                   .^~^                                               
  :?7   ^[email protected]@@@@@@#PJ!.      :!?YJ?~.JJ7.   !JJ7:    :YP!    ^7JYJ7.!YJ~    7YJ^  ^?JJ^  YG5!      .~?YY?!.?Y?^   .JJ7:   :7Y5J:   .!JPP5P5^ 
       7&@@BJ?!^::[email protected]@&?   ~P&@#J~!#[email protected]@@Y   [email protected]@@#:    [email protected] [email protected]@P!^Y##@@@^   [email protected]@[email protected]@@7 [email protected]@@#.   :Y#@@5!~GB&@@#.  [email protected]@@5 ~5P#@@@~  ?#@B?^[email protected]
[email protected]@@5.  .^^ [email protected]@@# [email protected]@@Y.   [email protected]@@&^  .#@@@&:   [email protected]^~#@@#~   [email protected]@@@5   [email protected]@@@[email protected]@J ^#@@@7   ?&@@G:   [email protected]@@@?  :#@@&YPP!Y&@@Y  [email protected]@#:  [email protected]
[email protected]@&J^[email protected]@@&[email protected]@@7    [email protected]@@#^   [email protected]@@@5    [email protected][email protected]@@G:   [email protected]@@Y   [email protected]@@&? [email protected]@5 :#@@&7   [email protected]@@5    :#@@@7  [email protected]@@&G! [email protected]@@5   ^&@@#?:~^   
     J&@#557^  :[email protected]@@G~ [email protected]@@?    !&@@B:  [email protected]@@@&^  :P&!:&@@#:   [email protected]@@J  .?&@@#~  :?J^:[email protected]@&!  :[email protected]@@P    :[email protected]@&!  :[email protected]@@#7  [email protected]@@Y   7BP~J#@#Y:   
     ^BB!.   [email protected]@@G!  .#@@G   :[email protected]@@G. ~PBY&@@@Y .?#G^ [email protected]@@!   [email protected]@@? .?#@@@B^       [email protected]@&~ ^5B&@@&:  .?#@@&~ :Y&@@@Y.  [email protected]@@5  7GG7~~  [email protected]@5   
    .#@~.^75#@@BJ^     [email protected]@[email protected]@@Y?GB?..&@@@J?GP~   ~&@@[email protected]@&[email protected]@@B:       .#@@B7PBY:[email protected]@&7!YGP&@@G7P&@@@B~    [email protected]@@?JBG!:[email protected]?.^[email protected]^   
     ~JY5PG5J!:         !J5YJ!. !Y55J~    ~Y5Y?!:      :?Y5Y?^ .?55Y7::5P5^         :?Y5Y!.   ^J55J7: ^J55Y!~Y5?.     .75P5J^  :G#PPGY~       

*/

//SPDX-License-Identifier: MIT
//Creator: Sergey K. / 24acht GmbH 


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
@title Non-Fungible Bavarians Genesis Token Contract 
@author Sergey K. / 24acht GmbH
@notice This ERC721 smart contract mints the team owners tokens and sets the specific IPFS-URI's accordingly. 
The list owners and the token uri's can be read from outside.
@dev Contract build on ERC721 openzepplin implementation
**/

contract GenesisNFBToken is ERC721 {

  /*
    Array of the owners' chosen wallet addresses in following order:
    1. Björn
    2. Manu
    3. Chris
    4. Tom
    5. Dominic
    6. Dimitres
    7. Kilian
    8. Leander
    9. Sergey K.
    10. Anna
    11. Peter
  */
  address[11] public owners = [
    0x16D2462cCD6104536c2a2EE3BB1fd998bE5C10A4,
    0x70F754869F66874513722001CDFfFd1b42182082,
    0x27148f5434dee32B36A569579133590f2EEF82d8,
    0x79da143f4C00d478712C5ea118A3a8e961A78EB4,
    0x29adE4a7e6eBF34CBd66F67BF66B65f127257FaF,
    0x7390a047Ef77781638874CC68BA7950be89B7622,
    0x960C6307A073dBC8346b7A0a057216300d8cf3BB,
    0x696696A44Ae7C5dB8Fe5c2cBfcFFC9875Eee42C2,
    0xe1A0894FEFA69C5041AEdcC445c994964Dc9Ec56,
    0x8d4Cbdd0D4f08790DCD077F1f4B392A8b5749234,
    0xa838c28201aBb6613022eC02B97fcF6828B0862B
    ];
    
  
  //string containing the IPFS-URI of the tokens JSON metadata
  string private _tokenBaseURI = "ipfs://bafybeifnjklyzfqz2wvpc562hcxpouombfiff46xkpifup4xgezwuhyfhm/";

  /**
  @notice The tokens name is "Genesis Non-Fungible Bavarians". The token symbol is gNFB (to differentiate it from normal NFB's).
  @dev Mint one token for each owner wallet.
  **/
  constructor() ERC721("Genesis Non-Fungible Bavarians", "gNFB") {
    for(uint8 i = 0; i < owners.length; i++) {
      _mint(owners[i], i+1);
    }
  }


  /**
  Function to update the tokens metadat URI.
  @notice Only the orginial founders of the token (Björn, Manuel and Chris) can call this function!
  @dev The founders addresses are the first three entries in the owners-array.
   */
  function setNewURI(string memory _newURI) external {
    require(msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2], "Only the tokens original founders can change the tokens metadata URI!");
    _tokenBaseURI = _newURI;
  }

  /** 
  @dev define base uri, which will later be used to create the full uri
  **/
  function _baseURI() override internal view returns(string memory) {
    return _tokenBaseURI;
  }

  /**
  * @dev Returns an URI for a given token ID
  */
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return string(abi.encodePacked(
        _baseURI(),
        Strings.toString(tokenId),
        ".json"
    ));
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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