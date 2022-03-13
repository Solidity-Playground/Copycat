// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";		//https://eips.ethereum.org/EIPS/eip-721
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IERC721URI.sol";   // Also Includes tokenURI()

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * Revision 221103
 * @title This is a Copycat NFT
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
	 * @dev Constructor
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
    function _unSetForward(uint256 tokenId) private {
        delete _forward[tokenId];
    }

    /**
     * @dev Decouple Tokens (By Owner)
     */
    function unSetForward(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _unSetForward(tokenId);
        //Emit URI Event
        emit URI("", tokenId);
    }

    /**
     * @dev Set Destination Token
     */
    function setForward(uint256 tokenId, address destContract, uint256 destTokenId) public {
        //Validate
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(_msgSender() == IERC721URI(destContract).ownerOf(destTokenId), "Caller is Not Target Token Owner");
        //Check if Contract Exists & It's an ERC721 or Compatible
        require(IERC721URI(destContract).supportsInterface(0x80ac58cd), "Destination Contract is Not ERC721 Compatible");
        //Set
        _forward[tokenId]._contract = destContract;    //ERC721
        _forward[tokenId]._id = destTokenId;
        //Emit URI Event
        emit URI(tokenURI(tokenId), tokenId);
    }

    /**
     * @dev Forward token URI Requests to Destination Token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        //Forward
        return IERC721URI(_forward[tokenId]._contract).tokenURI(_forward[tokenId]._id);
    }

    /**
     * @dev forward token's ownership Requests to destination token
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if(_forward[tokenId]._contract == address(0)) return address(0);
        //Forward
        return IERC721URI(_forward[tokenId]._contract).ownerOf(_forward[tokenId]._id);
    }

    /** [CANCELLED] Now tracking ownership as well
     * @dev Make sure that Destination token is Still owned By the same Owner
     * - Can be called by anyone
     
    function validateToken(uint256 tokenId) public {
        //If Not Token Owner
        if(ownerOf(tokenId) != IERC721URI(_forward[tokenId]._contract).ownerOf(_forward[tokenId]._id)){
            //Decouple Tokens
            _unSetForward(tokenId);
        }
    }
    */

}