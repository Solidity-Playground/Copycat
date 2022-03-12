// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";		//https://eips.ethereum.org/EIPS/eip-721
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IERC721URI.sol";   // Includes tokenURI()

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * This is a Copycat NFT
 * - It forwards URI Requests to a destination NFT
 * - Destination NFT must be owned by same account when the copy is made
 * - ... Should probably validate that the destination NFT is still owned by the same account
 * - Optimistic - Anyone can call a function that removes the forward if the underlying token changed owner
 * 
 * [Token] --> [Contract:Token]     Reference
 *  URI    <--   URI                Inheritance
 */
contract Copycat is ERC721 {

    //Track Token IDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct NFT {
        address _contract;
        uint256 _id;
    }

    //Forward Mapping
    mapping(uint256 => NFT) public _forward;

	/**
	 * @dev URI Change Event
	 */
    event URI(string value, uint256 indexed id);    //Copied from ERC1155

    /**
	 * Constructor
	 */
    constructor() ERC721("NFT Proxy", "COPYCAT") {

    }

    /**
     * @dev mint new Token (To Oneself)
     */
    function mintAndSet(address destContract, uint256 destTokenId) public returns (uint256) {
        // //Validate - Bot Protection
        // require(tx.origin == msg.sender, "Bots not allowed");
        //Mint
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);       //For Self Only
        //Set Forward
        setForward(newItemId, destContract, destTokenId);
        
        //Done
        return newItemId;
    }

    /**
     * @dev mint new Token (To Oneself)
     */
    function mint() external returns (uint256) {
        //Mint
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);       //For Self Only
        //Done
        return newItemId;
    }

    /** 
     * @dev Decouple Tokens
     */
    function _unSetForward(uint256 token_id) private {
        delete _forward[token_id];
    }

    /**
     * @dev Decouple Tokens (By Owner)
     */
    function unSetForward(uint256 token_id) external {
        require(_isApprovedOrOwner(_msgSender(), token_id), "Caller is not owner nor approved");
        _unSetForward(token_id);
        //Emit URI Event
        emit URI('', token_id);
    }

    /**
     * @dev Set Destination Token
     */
    function setForward(uint256 token_id, address destContract, uint256 destTokenId) public {
        //Validate
        require(_isApprovedOrOwner(_msgSender(), token_id), "Caller is not owner nor approved");
        require(_msgSender() == IERC721URI(destContract).ownerOf(destTokenId), "Caller is Not Target Token Owner");
        //Check if Contract Exists & It's an ERC721 or Compatible
        require(IERC721URI(destContract).supportsInterface(0x80ac58cd), "Destination Contract is Not ERC721 Compatible");
        //Set
        _forward[token_id]._contract = destContract;    //ERC721
        _forward[token_id]._id = destTokenId;
        //Emit URI Event
        emit URI(tokenURI(token_id), token_id);
    }

    /**
     * @dev Forward token URI Requests to Destination Token
     */
    function tokenURI(uint256 token_id) public view override returns (string memory) {
        //Validate
        // require(ownerOf(token_id) == IERC721URI(_forward[token_id]._contract).ownerOf(_forward[token_id]._id), "No Longer Token Owner"); //ERROR: The called function should be payable if you send value and the value you send should be less than your current balance.
        //Forward
        return IERC721URI(_forward[token_id]._contract).tokenURI(_forward[token_id]._id);
    }

    /**
     * @dev forward token URI Requests to destination token
     */
    function ownerOf(uint256 token_id) public view override returns (address) {
        if(_forward[token_id]._contract == address(0)) return address(0);
        //Forward
        return IERC721URI(_forward[token_id]._contract).ownerOf(_forward[token_id]._id);
    }

    /**
     * @dev Make sure that Destination token is Still owned By the same Owenr
     * - Can be called by anyone
     */
    function validateToken(uint256 token_id) public {
        //If Not Token Owner
        if(ownerOf(token_id) != IERC721URI(_forward[token_id]._contract).ownerOf(_forward[token_id]._id)){
            //Decouple Tokens
            _unSetForward(token_id);
        }
    }

    /**
     * [DEV] Try Self Destruct
     */
    function selfDestruct(address _address) public { 
        selfdestruct(payable(_address)); 
    }

}