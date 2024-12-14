// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../ERC721SeaDrop.sol";
import { MetadataRenderer } from "./MetadataRenderer.sol";

/**
 * @title ERC721SeaDropCustom
 * @notice Custom implementation of ERC721SeaDrop with additional metadata rendering functionality
 * @dev Extends ERC721SeaDrop to add custom metadata handling and token value locking
 */
contract ERC721SeaDropCustom is ERC721SeaDrop {
    /// @notice The metadata renderer contract that generates token URIs and handles metadata
    MetadataRenderer public metadataRenderer;

    /// @notice Emitted when a token's values are permanently locked
    /// @param tokenId The ID of the token whose values were locked
    /// @param owner The address of the owner who locked the token
    event TokenValuesLocked(uint256 indexed tokenId, address indexed owner);

    /**
     * @notice Initializes the contract with name, symbol, and allowed SeaDrop addresses
     * @param name The name of the NFT collection
     * @param symbol The symbol of the NFT collection
     * @param allowedSeaDrop Array of allowed SeaDrop contract addresses
     */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {}

    /**
     * @notice Sets the address of the metadata renderer contract
     * @param _renderer Address of the new metadata renderer
     * @dev Only callable by contract owner
     */
    function setMetadataRenderer(address _renderer) external onlyOwner {
        metadataRenderer = MetadataRenderer(_renderer);
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param tokenId The ID of the token to get the URI for
     * @return The token's URI string
     * @dev Overrides the parent contract's tokenURI function
     */
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

    /**
     * @notice Mints tokens through the SeaDrop contract
     * @param minter Address to mint the tokens to
     * @param quantity Number of tokens to mint
     * @dev Overrides the parent contract's mintSeaDrop function to add custom metadata logic
     */
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

        // Initialize metadata for each minted token
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _totalMinted() - quantity + i + 1;
            metadataRenderer.setInitialMetadata(tokenId);
        }
    }

    /**
     * @notice Locks a token's values permanently
     * @param tokenId The ID of the token to lock
     * @dev Can only be called by the token owner
     */
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