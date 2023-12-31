// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

///@title SpitBuddies - A collaboration between Llamaverse and PG
///@author WhiteOakKong
///@notice SpitBuddies is an ERC721A contract that allows for minting 200 spitbuddies.

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721A } from "@erc721a/contracts/ERC721A.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SpitBuddies is ERC721A, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseURI;
    string public URIExtension;
    uint256 public constant MAX_SUPPLY = 200;
    address public spitYard;

    event SpitYardChanged(address indexed _newSpitYard);
    event BaseURIChanged(string _newBaseURI);
    event URIExtensionChanged(string _newURIExtension);

    constructor() ERC721A("Spit Buddies", "SPITBUD") {
        _mint(msg.sender, 1);
    }

    ///@notice batch mint of max supply
    ///@dev can only be called once
    ///@param addressArray array of addresses to mint to
    function batchMint(address[] calldata addressArray) external onlyOwner {
        require(addressArray.length == MAX_SUPPLY, "Incorrect Array Length");
        require(_totalMinted() < MAX_SUPPLY, "Already Minted");
        for (uint256 i; i < MAX_SUPPLY; i++) {
            _mint(addressArray[i], 1);
        }
    }

    ///@notice sets baseURI for collection metadata
    ///@param _baseURI baseURI to set
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIChanged(_baseURI);
    }

    ///@notice sets URIExtension for collection metadata
    ///@param _extension URIExtension to set
    function setURIExtension(string memory _extension) external onlyOwner {
        URIExtension = _extension;
        emit URIExtensionChanged(_extension);
    }

    ///@notice sets SpitYard address
    ///@param _spitYard SpitYard address to set
    function setSpitYard(address _spitYard) external onlyOwner {
        require(_spitYard != address(0), "Invalid address");
        spitYard = _spitYard;
        emit SpitYardChanged(_spitYard);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), URIExtension));
    }

    ///@notice Autoapproval for SpitYard
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if (operator == spitYard) {
            return true;
        } else {
            return super.isApprovedForAll(owner, operator);
        }
    }

    ///@notice burn function for owner only - used for mainnet verification prior to airdrop.
    function burnTestToken() external onlyOwner {
        _burn(0);
    }

    // ============ OPERATOR-FILTER-OVERRIDES ============

    // function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator)
    // {
    //     super.setApprovalForAll(operator, approved);
    // }

    // function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator)
    // {
    //     super.approve(operator, tokenId);
    // }

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // )
    //     public
    //     payable
    //     override
    //     onlyAllowedOperator(from)
    // {
    //     super.transferFrom(from, to, tokenId);
    // }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // )
    //     public
    //     payable
    //     override
    //     onlyAllowedOperator(from)
    // {
    //     super.safeTransferFrom(from, to, tokenId);
    // }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes memory data
    // )
    //     public
    //     payable
    //     override
    //     onlyAllowedOperator(from)
    // {
    //     super.safeTransferFrom(from, to, tokenId, data);
    // }
}
