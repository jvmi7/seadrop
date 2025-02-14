// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../ERC721SeaDrop.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { IChartsErrors } from "./interfaces/IChartsErrors.sol";
import { Palettes } from "./libraries/Palettes.sol";
import { Constants } from "./libraries/Constants.sol";

/**
 * @title ChartsERC721SeaDrop
 * @notice Handles NFT minting, metadata rendering, and palette conversions
 * @dev Extends ERC721SeaDrop to add custom metadata handling and token conversion mechanics
 */
contract ChartsERC721SeaDrop is ERC721SeaDrop, IChartsErrors {
    /*************************************/
    /*              Storage              */
    /*************************************/
    /// @notice The metadata renderer contract that generates token URIs and handles metadata
    IMetadataRenderer public metadataRenderer;

    /*************************************/
    /*              Events               */
    /*************************************/
    /// @notice Emitted when tokens are elevated to a different palette
    event TokensElevated(
        uint256 elevateTokenId,
        uint256 burnTokenId
    );

    /// @notice Emitted when the metadata renderer contract is updated
    event MetadataRendererUpdated(address indexed oldRenderer, address indexed newRenderer);

    /*************************************/
    /*             Constructor           */
    /*************************************/
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

    /*************************************/
    /*         External Functions        */
    /*************************************/
    /**
     * @notice Sets the address of the metadata renderer contract
     * @param _renderer Address of the new metadata renderer
     * @dev Only callable by contract owner
     */
    function setMetadataRenderer(address _renderer) external onlyOwner {
        if (_renderer == address(0)) {
            revert InvalidAddress(_renderer);
        }
        address oldRenderer = address(metadataRenderer);
        metadataRenderer = IMetadataRenderer(_renderer);
        emit MetadataRendererUpdated(oldRenderer, _renderer);
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

        // Check if the metadata renderer is set
        if (address(metadataRenderer) == address(0)) {
            revert MetadataError();
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
     * @notice Converts tokens to a different palette by burning existing tokens and minting a new one
     * @param elevateTokenId The ID of the token to elevate
     * @param burnTokenId The ID of the token to burn
     */
    function elevate(uint256 elevateTokenId, uint256 burnTokenId)
        external
        nonReentrant
    {
        // Check if the tokens are valid for elevation
        _validateElevation(elevateTokenId, burnTokenId);

        uint8 newPalette = createElevatedPalette(elevateTokenId, burnTokenId);

        // create a hash from the msg.sender and the two token ids
        bytes32 seed = keccak256(abi.encodePacked(elevateTokenId, burnTokenId));

        // Effects
        // Generate the metadata for the new token & set it to the 0th token
        metadataRenderer.setElevatedToken(elevateTokenId, newPalette, seed);

        // Burn the 1st token
        _burn(burnTokenId);

        if (!metadataRenderer.getIsElevatedToken(elevateTokenId)) {
            revert TokenError(elevateTokenId);
        }

        emit TokensElevated(elevateTokenId, burnTokenId);
    }

    function createElevatedPalette(uint256 elevateTokenId, uint256 burnTokenId) private view returns (uint8) {
        uint8 elevatePalette = metadataRenderer.getTokenPalette(elevateTokenId);
        uint8 burnPalette = metadataRenderer.getTokenPalette(burnTokenId);

        if (elevatePalette < Constants.CHROMATIC && burnPalette < Constants.CHROMATIC) {
            return Constants.CHROMATIC;
        }
        if (elevatePalette == Constants.CHROMATIC && burnPalette == Constants.CHROMATIC) {
            return Constants.PASTEL;
        }
        if (elevatePalette == Constants.PASTEL && burnPalette == Constants.PASTEL) {
            return Constants.GREYSCALE;
        }
        revert ElevateError(elevateTokenId, burnTokenId);
    }

    function _validateElevation(uint256 elevateTokenId, uint256 burnTokenId) private view {
        // Prevent duplicate token IDs
        if (burnTokenId == elevateTokenId) revert ElevateError(elevateTokenId, burnTokenId);
        
        // Check existence and ownership of both tokens
        if (!_exists(elevateTokenId) || ownerOf(elevateTokenId) != msg.sender) {
            revert NotTokenOwner(msg.sender, elevateTokenId, _exists(elevateTokenId) ? ownerOf(elevateTokenId) : address(0));
        }
        if (!_exists(burnTokenId) || ownerOf(burnTokenId) != msg.sender) {
            revert NotTokenOwner(msg.sender, burnTokenId, _exists(burnTokenId) ? ownerOf(burnTokenId) : address(0));
        }

        // Validate palette levels are the same for both tokens
        uint8 elevatePalette = metadataRenderer.getTokenPalette(elevateTokenId);
        uint8 burnPalette = metadataRenderer.getTokenPalette(burnTokenId);

        // Cannot burn a greyscale token
        if (elevatePalette == Constants.GREYSCALE || burnPalette == Constants.GREYSCALE) {
            revert ElevateError(elevateTokenId, burnTokenId);
        }

        // For chromatic, pastel, or greyscale, palettes must match exactly. 
        if ((elevatePalette == Constants.CHROMATIC && burnPalette == Constants.CHROMATIC) ||
            (elevatePalette == Constants.PASTEL && burnPalette == Constants.PASTEL)) {
            if (elevatePalette != burnPalette) {
                revert ElevateError(elevateTokenId, burnTokenId);
            }
        }
    }
}