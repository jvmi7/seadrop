// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../ERC721SeaDrop.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { Constants } from "./libraries/Constants.sol";
import "./interfaces/IChartsErrors.sol";

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

    /// @notice Mapping of palette conversions
    mapping(uint8 => PaletteConversion) public paletteConversions;

    /*************************************/
    /*              Structs              */
    /*************************************/
    struct PaletteConversion {
        uint8 requiredPalette;
        uint8 resultPalette;
        uint8 requiredTokenCount;
    }

    /*************************************/
    /*              Events               */
    /*************************************/
    /// @notice Emitted when a token's values are permanently locked
    event TokenValuesLocked(uint256 indexed tokenId, address indexed owner);

    /// @notice Emitted when tokens are converted to a different palette
    event TokensConverted(
        uint256[] burnedTokenIds,
        uint256 newTokenId,
        uint8 targetPalette
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
            resultPalette: 0,
            requiredTokenCount: 2
        });
    }

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
            revert InvalidAddress(_renderer, "Zero address not allowed");
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
            revert MetadataError("Renderer not set");
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
        if (!_exists(tokenId)) {
            revert TokenError(tokenId, "Token does not exist");
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner(msg.sender, tokenId, ownerOf(tokenId));
        }
        if (address(metadataRenderer) == address(0)) {
            revert MetadataError("Renderer not set");
        }

        // Call the metadata renderer's lock function
        try metadataRenderer.lockTokenValues(tokenId) {
            emit TokenValuesLocked(tokenId, msg.sender);
        } catch Error(string memory reason) {
            revert MetadataError(reason);
        } catch {
            revert MetadataError("Lock operation failed");
        }
    }

    /**
     * @notice Converts tokens to a different palette by burning existing tokens and minting a new one
     * @param tokenIds Array of token IDs to convert
     * @param targetPalette The desired palette for the newly minted token
     * @dev For chromatic conversion, requires 4 different base palette tokens
     * @dev For other conversions, requires tokens of the same required palette
     */
    function convertTokens(uint256[] calldata tokenIds, uint8 targetPalette)
        external
        nonReentrant
    {
        // Check tokenIds length
        if (tokenIds.length == 0 || tokenIds.length > 4) {
            revert InvalidTokenInput(tokenIds, "Must provide 1-4 tokens");
        }

        // Check if conversion is available
        PaletteConversion memory conversion = paletteConversions[targetPalette];
        if (conversion.resultPalette == 0) {
            revert ConversionError(0, targetPalette, "Conversion not available");
        }

        // Check if the correct number of tokens are provided
        if (tokenIds.length != conversion.requiredTokenCount) {
            revert InvalidTokenInput(
                tokenIds, 
                "Wrong number of tokens for conversion"
            );
        }
        
        // Check all tokens exist and are owned by sender
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_exists(tokenIds[i])) {
                revert TokenError(tokenIds[i], "Token does not exist");
            }
            if (ownerOf(tokenIds[i]) != msg.sender) {
                revert NotTokenOwner(msg.sender, tokenIds[i], ownerOf(tokenIds[i]));
            }
        }

        // Check for duplicate token IDs
        if (tokenIds.length > 1) {
            for (uint256 i = 0; i < tokenIds.length - 1; i++) {
                for (uint256 j = i + 1; j < tokenIds.length; j++) {
                    if (tokenIds[i] == tokenIds[j]) {
                        revert TokenError(tokenIds[i], "Duplicate token ID");
                    }
                }
            }
        }

        // Verify palettes
        if (conversion.requiredPalette == type(uint8).max) {
            _validateChromaticConversion(tokenIds);
        } else {
            _validatePastelGreyscaleConversion(tokenIds, conversion.requiredPalette);
        }

        // Effects
        uint256 newTokenId = _totalMinted() + 1;
        _safeMint(msg.sender, 1);
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }

        metadataRenderer.setSpecialToken(newTokenId, conversion.resultPalette);

        if (!metadataRenderer.getIsSpecialToken(newTokenId)) {
            revert TokenError(newTokenId, "New token is not a special token");
        }

        emit TokensConverted(tokenIds, newTokenId, targetPalette);
    }

    /// @dev Validates tokens for chromatic conversion
    function _validateChromaticConversion(uint256[] calldata tokenIds) private view {
        bool[4] memory basepalettesFound;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint8 tokenPalette = metadataRenderer.getTokenPalette(tokenIds[i]);
            if (tokenPalette >= Constants.PALETTE_CHROMATIC) {
                revert InvalidPalette(tokenPalette, "Must be base palette");
            }
            if (basepalettesFound[tokenPalette]) {
                revert ConversionError(
                    tokenPalette,
                    Constants.PALETTE_CHROMATIC,
                    "Duplicate palette"
                );
            }
            basepalettesFound[tokenPalette] = true;
        }
        
        // Verify all palettes were found
        for (uint256 i = 0; i < 4; i++) {
            if (!basepalettesFound[i]) {
                revert ConversionError(
                    uint8(i),
                    Constants.PALETTE_CHROMATIC,
                    "Missing required palette"
                );
            }
        }
    }

    /// @dev Validates tokens for standard conversion
    function _validatePastelGreyscaleConversion(
        uint256[] calldata tokenIds, 
        uint8 requiredPalette
    ) private view {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint8 tokenPalette = metadataRenderer.getTokenPalette(tokenIds[i]);
            if (tokenPalette != requiredPalette) {
                revert ConversionError(
                    tokenPalette,
                    requiredPalette,
                    "Wrong palette for conversion"
                );
            }
        }
    }
}