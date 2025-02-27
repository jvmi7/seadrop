// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../ERC721SeaDrop.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { IChartsErrors } from "./interfaces/IChartsErrors.sol";
import { Palettes } from "./libraries/Palettes.sol";
import { Constants } from "./libraries/Constants.sol";
import { MetadataUtils } from "./libraries/MetadataUtils.sol";

/**
 * @title ChartsERC721SeaDrop
 * @dev A custom ERC721SeaDrop contract for the charts collection
 */
contract ChartsERC721SeaDrop is ERC721SeaDrop, IChartsErrors {
    /*************************************/
    /*              Storage              */
    /*************************************/

    // @notice The metadata renderer contract that handles metadata generation
    IMetadataRenderer public metadataRenderer;

    // @notice Boolean to track if elevation is enabled
    bool public isElevationEnabled;

    /*************************************/
    /*              Events               */
    /*************************************/

    // @notice Emitted when tokens are elevated
    event TokensElevated(uint256 elevateTokenId, uint256 burnTokenId);

    // @notice Emitted when the metadata renderer contract is updated
    event MetadataRendererUpdated(address indexed newRenderer, address indexed oldRenderer);

    // @notice Emitted when the metadata of a token is changed (ERC-4906)
    event MetadataUpdate(uint256 _tokenId);

    // @notice Emitted when the elevation status is updated
    event ElevationStatusUpdated(bool isEnabled);

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
     * @param _metadataRenderer Address of the new metadata renderer
     * @dev Only callable by contract owner
     */
    function setMetadataRenderer(address _metadataRenderer) external onlyOwner {
        address oldRenderer = address(metadataRenderer);
        metadataRenderer = IMetadataRenderer(_metadataRenderer);
        emit MetadataRendererUpdated(_metadataRenderer, oldRenderer);
    }

    /**
     * @notice Enables or disables the elevation functionality
     * @param _isEnabled Boolean indicating if elevation should be enabled
     * @dev Only callable by contract owner
     */
    function setElevationStatus(bool _isEnabled) external onlyOwner {
        isElevationEnabled = _isEnabled;
        emit ElevationStatusUpdated(_isEnabled);
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param tokenId The ID of the token to get the URI for
     * @return The token's URI string
     * @dev Overrides the parent contract's tokenURI function
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return metadataRenderer.getTokenURI(tokenId);
    }

    /**
     * @notice Mints tokens through the SeaDrop contract
     * @param minter Address to mint the tokens to
     * @param quantity Number of tokens to mint
     * @dev Overrides the parent contract's mintSeaDrop function to add custom metadata logic
     */
    function mintSeaDrop(address minter, uint256 quantity) external override nonReentrant {
        // Ensure the SeaDrop is allowed
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(_totalMinted() + quantity, maxSupply());
        }

        // Check if the metadata renderer is set
        if (address(metadataRenderer) == address(0)) {
            revert ContractNotSet("metadataRenderer");
        }

        // Mint the quantity of tokens to the minter
        _safeMint(minter, quantity);

        // Initialize metadata for each minted token
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _totalMinted() - quantity + i + 1;
            metadataRenderer.initializeTokenMetadata(tokenId);
        }
    }

    /**
     * @notice Converts tokens to a different palette by burning existing tokens and minting a new one
     * @param elevateTokenId The ID of the token to elevate
     * @param burnTokenId The ID of the token to burn
     */
    function elevate(uint256 elevateTokenId, uint256 burnTokenId) external nonReentrant {
        // Check if elevation is enabled
        if (!isElevationEnabled) revert ElevationDisabled();

        // Check if the tokens are valid for elevation
        _validateElevation(elevateTokenId, burnTokenId);

        // Save the previous metadata values
        uint8 prevPalette = metadataRenderer.tokenPalettes(elevateTokenId);
        uint8 prevTier = MetadataUtils.calculateTierFromPalette(prevPalette);
        bytes32 prevSeed = metadataRenderer.tokenSeeds(elevateTokenId);

        // Elevate the token
        metadataRenderer.elevate(elevateTokenId, burnTokenId);

        // Get the new metadata values
        uint8 newPalette = metadataRenderer.tokenPalettes(elevateTokenId);
        uint8 newTier = MetadataUtils.calculateTierFromPalette(newPalette);
        bytes32 newSeed = metadataRenderer.tokenSeeds(elevateTokenId);

        // Verify the elevation
        if (newTier != prevTier + 1) revert ElevationError(elevateTokenId, burnTokenId);
        if (newPalette == prevPalette) revert ElevationError(elevateTokenId, burnTokenId);
        if (newSeed == prevSeed) revert ElevationError(elevateTokenId, burnTokenId);

        // Burn the designated token
        _burn(burnTokenId);

        // Emit events
        emit TokensElevated(elevateTokenId, burnTokenId);
        emit MetadataUpdate(elevateTokenId);
    }

    function _validateElevation(uint256 elevateTokenId, uint256 burnTokenId) private view {
        // Prevent duplicate token IDs
        if (burnTokenId == elevateTokenId) revert ElevationError(elevateTokenId, burnTokenId);

        // Check existence of elevate token
        if (!_exists(elevateTokenId)) {
            revert TokenDoesNotExist(elevateTokenId);
        }

        // Check existence of burn token
        if (!_exists(burnTokenId)) revert TokenDoesNotExist(burnTokenId);

        // Check ownership of elevate token
        if (ownerOf(elevateTokenId) != msg.sender) {
            revert NotTokenOwner(msg.sender, elevateTokenId, ownerOf(elevateTokenId));
        }

        // Check ownership of burn token
        if (ownerOf(burnTokenId) != msg.sender) {
            revert NotTokenOwner(msg.sender, burnTokenId, ownerOf(burnTokenId));
        }
    }
}
