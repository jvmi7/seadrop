// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../ERC721SeaDrop.sol";
import { MetadataRenderer } from "./MetadataRenderer.sol";

contract ERC721SeaDropCustom is ERC721SeaDrop {
    MetadataRenderer public metadataRenderer;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    function setMetadataRenderer(address _renderer) external onlyOwner {
        metadataRenderer = MetadataRenderer(_renderer);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return metadataRenderer.generateTokenURI(tokenId);
    }

    function mintSeaDrop(address minter, uint256 quantity)
        external
        virtual
        override
        nonReentrant
    {
        // Ensure the SeaDrop is allowed
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter
        _safeMint(minter, quantity);

        // Add our custom metadata logic
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _totalMinted() - quantity + i + 1;
            metadataRenderer.setInitialMetadata(tokenId);
        }
    }

    event TokenValuesLocked(uint256 indexed tokenId, address indexed owner);

    function lockTokenValues(uint256 tokenId) external nonReentrant {
        // Check that the token exists and sender is the owner
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        // Check that metadata renderer is set
        require(address(metadataRenderer) != address(0), "Metadata renderer not set");
        
        // Call the metadata renderer's lock function
        metadataRenderer.lockTokenValues(tokenId);
        
        emit TokenValuesLocked(tokenId, msg.sender);
    }
}