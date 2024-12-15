// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../ERC721SeaDrop.sol";
import { MetadataRenderer } from "./MetadataRenderer.sol";
import { Constants } from "./libraries/Constants.sol";

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

    /// @notice Mapping of palette conversions
    mapping(uint8 => PaletteConversion) public paletteConversions;

    struct PaletteConversion {
        uint8 requiredPalette;
        uint8 resultPalette;
        uint8 requiredTokenCount;
    }

    /// @notice Emitted when tokens are converted to a different palette
    /// @param burnedTokenIds Array of burned token IDs
    /// @param newTokenId ID of the new minted token
    /// @param targetPalette Target palette for conversion
    event TokensConverted(
        uint256[] burnedTokenIds,
        uint256 newTokenId,
        uint8 targetPalette
    );

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
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {
        // Set up conversion rules
        paletteConversions[Constants.PALETTE_CHROMATIC] = PaletteConversion({
            requiredPalette: type(uint8).max,
            resultPalette: Constants.PALETTE_CHROMATIC,
            requiredTokenCount: 4
        });
        
        paletteConversions[Constants.PALETTE_PASTEL] = PaletteConversion({
            requiredPalette: Constants.PALETTE_CHROMATIC,
            resultPalette: Constants.PALETTE_PASTEL,
            requiredTokenCount: 3
        });
        
        paletteConversions[Constants.PALETTE_GREYSCALE] = PaletteConversion({
            requiredPalette: Constants.PALETTE_PASTEL,
            resultPalette: Constants.PALETTE_GREYSCALE,
            requiredTokenCount: 2
        });
    }

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

    /**
     * @notice Converts tokens to a different palette by burning existing tokens and minting a new one
     * @param tokenIds Array of token IDs to convert (must be exactly 4 tokens)
     * @param targetPalette The desired palette for the newly minted token
     * @dev Verifies token ownership, checks for valid palette combinations, burns input tokens, and mints a new token
     * @dev For chromatic conversion, requires 4 different base palette tokens
     * @dev For other conversions, requires 4 tokens of the same required palette
     */
    function convertTokens(uint256[] calldata tokenIds, uint8 targetPalette) 
        external 
        nonReentrant 
    {
        PaletteConversion memory conversion = paletteConversions[targetPalette];
        require(conversion.resultPalette != 0, "Conversion not available");
        require(tokenIds.length == conversion.requiredTokenCount, 
            "Invalid number of tokens");
            
        // Check for duplicate token IDs
        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate token ID");
            }
        }

        // Verify ownership and palettes
        if (conversion.requiredPalette == type(uint8).max) {
            // For chromatic conversion, check for 4 different base palettes
            bool[4] memory basepalettesFound;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(_exists(tokenIds[i]), "Token does not exist");
                require(ownerOf(tokenIds[i]) == msg.sender, "Not token owner");
                
                uint8 tokenPalette = metadataRenderer.getTokenPalette(tokenIds[i]);
                require(tokenPalette < Constants.PALETTE_CHROMATIC, 
                    "Invalid token palette");
                require(!basepalettesFound[tokenPalette], 
                    "Duplicate palette");
                basepalettesFound[tokenPalette] = true;
            }
        } else {
            // For other conversions, verify all tokens are of required palette
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(_exists(tokenIds[i]), "Token does not exist");
                require(ownerOf(tokenIds[i]) == msg.sender, "Not token owner");
                
                uint8 tokenPalette = metadataRenderer.getTokenPalette(tokenIds[i]);
                require(tokenPalette == conversion.requiredPalette, 
                    "Wrong palette for conversion");
            }
        }

        uint256 newTokenId = _totalMinted() + 1;
        _safeMint(msg.sender, 1);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }

        metadataRenderer.setSpecialToken(newTokenId, conversion.resultPalette);

        emit TokensConverted(tokenIds, newTokenId, targetPalette);
    }
}