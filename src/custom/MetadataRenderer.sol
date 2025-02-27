// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { TokenMetadata } from "./types/MetadataTypes.sol";
import { Constants } from "./libraries/Constants.sol";
import { IValueGenerator } from "./interfaces/IValueGenerator.sol";
import { ArrayUtils } from "./libraries/ArrayUtils.sol";
import { MetadataImplementation } from "./MetadataImplementation.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import { LegendaryValues } from "./libraries/LegendaryValues.sol";
import { MetadataUtils } from "./libraries/MetadataUtils.sol";
import { Utils } from "./libraries/Utils.sol";

/**
 * @title MetadataRenderer
 * @notice Handles the generation and management of NFT metadata for the charts collection
 * @dev This contract works in conjunction with ValueGenerator & MetadataImplementation contracts
 */
contract MetadataRenderer is IMetadataRenderer, Ownable {
    using Strings for uint256;
    using ArrayUtils for uint8[7];

    /*************************************/
    /*              Constants            */
    /*************************************/

    // @notice Size of the values array for each token
    uint256 private constant VALUES_ARRAY_SIZE = 7;

    /*************************************/
    /*              Storage              */
    /*************************************/

    // @notice Contract that implements the metadata generation logic
    MetadataImplementation public metadataImplementation;
    // @notice Contract that generates the token values trait
    IValueGenerator public valueGenerator;

    // @notice Address of the NFT contract that this renderer serves
    address public immutable nftContract;
    // @notice URL for rendering the nft animation
    string public animationUrl;
    // @notice Global seed used for determining the current elevation result.
    // This seed is updated with every elevation, manipulating the results for
    // all tokens each time an elevation event occurs.
    bytes32 public globalSeed;

    // @notice Maps token IDs to their color palettes
    mapping(uint256 => uint8) public tokenPalettes;
    // @notice Maps token IDs to their seeds.
    // These seeds are used to generate the values for each token.
    // When a token is elevated, this map is updated with a new seed.
    mapping(uint256 => bytes32) public tokenSeeds;

    /*************************************/
    /*              Errors               */
    /*************************************/

    // @notice Thrown when the metadata implementation is invalid
    error InvalidMetadataImplementation();
    // @notice Thrown when the value generator is invalid
    error InvalidValueGenerator();
    // @notice Thrown when the caller is not the NFT contract
    error OnlyNFTContract();
    // @notice Thrown when the elevation is invalid
    error InvalidElevation(uint256 elevateTokenId, uint256 burnTokenId);

    /*************************************/
    /*              Constructor          */
    /*************************************/

    /**
     * @notice Initializes the contract with necessary dependencies
     * @param _nftContract Address of the NFT contract
     * @param _valueGenerator Address of the value generator contract
     * @param _metadataImplementation Address of the MetadataImplementation contract
     */
    constructor(address _nftContract, address _metadataImplementation, address _valueGenerator) {
        nftContract = _nftContract;
        metadataImplementation = MetadataImplementation(_metadataImplementation);
        valueGenerator = IValueGenerator(_valueGenerator);
        animationUrl = Constants.ANIMATION_URL;
        globalSeed = Utils.generateNextSeed(Utils.generateRandomSeed(), 0);
    }

    /*************************************/
    /*              Modifiers            */
    /*************************************/

    /**
     * @notice Ensures only the NFT contract can call certain functions
     * @dev Used for functions that manage token metadata
     */
    modifier onlyNFTContract() {
        if (msg.sender != nftContract) revert OnlyNFTContract();
        _;
    }

    /*************************************/
    /*              Getters              */
    /*************************************/

    /**
     * @notice Gets the complete token URI for a given token
     * @param tokenId The ID of the token to get the URI for
     * @return The complete token URI as a string
     */
    function getTokenURI(uint256 tokenId) external view returns (string memory) {
        TokenMetadata memory metadata = _createTokenMetadata(tokenId);
        return metadataImplementation.generateTokenURI(metadata);
    }

    /*************************************/
    /*              Setters              */
    /*************************************/

    /**
     * @notice Sets the address of the MetadataImplementation contract
     * @param _metadataImplementation The new address of the MetadataImplementation contract
     * @dev Only callable by the contract owner
     */
    function setMetadataImplementation(address _metadataImplementation) external onlyOwner {
        if (_metadataImplementation == address(0)) revert InvalidMetadataImplementation();
        metadataImplementation = MetadataImplementation(_metadataImplementation);
    }

    /**
     * @notice Sets the address of the ValueGenerator contract
     * @param _valueGenerator The new address of the ValueGenerator contract
     * @dev Only callable by the contract owner
     */
    function setValueGenerator(address _valueGenerator) external onlyOwner {
        if (_valueGenerator == address(0)) revert InvalidValueGenerator();
        valueGenerator = IValueGenerator(_valueGenerator);
    }

    /**
     * @notice Sets the animation URL
     * @param _animationUrl The new animation URL
     */
    function setAnimationUrl(string memory _animationUrl) external onlyOwner {
        animationUrl = _animationUrl;
    }

    /*************************************/
    /*              External             */
    /*************************************/

    /**
     * @notice Sets the initial metadata for a newly minted token
     * @param tokenId The ID of the token to set metadata for
     */
    function initializeTokenMetadata(uint256 tokenId) external onlyNFTContract {
        // If the token is legendary, set the palette to legendary
        if (LegendaryValues.isLegendary(tokenId)) {
            tokenPalettes[tokenId] = Constants.LEGENDARY;
        } else {
            // Otherwise, calculate the palette based on the token ID
            uint8 palette = MetadataUtils.calculateGenesisPalette(tokenId);
            tokenPalettes[tokenId] = palette;
        }
    }

    /**
     * @notice Elevates a token by burning another token and setting the palette to the next tier
     * @param elevateTokenId The ID of the token to elevate
     * @param burnTokenId The ID of the token to burn
     * @dev Only callable by NFT contract and requires elevated palette range
     */
    function elevate(uint256 elevateTokenId, uint256 burnTokenId) external onlyNFTContract {
        // Validate the tokens are able to be elevated
        uint8 elevatePalette = tokenPalettes[elevateTokenId];
        uint8 burnPalette = tokenPalettes[burnTokenId];
        uint8 elevateTier = MetadataUtils.calculateTierFromPalette(elevatePalette);
        uint8 burnTier = MetadataUtils.calculateTierFromPalette(burnPalette);

        // Must be the same tier
        if (elevateTier != burnTier) revert InvalidElevation(elevateTokenId, burnTokenId);
        // Cannot elevate greyscale
        if (elevatePalette == Constants.GREYSCALE || burnPalette == Constants.GREYSCALE)
            revert InvalidElevation(elevateTokenId, burnTokenId);
        // Cannot elevate legendary
        if (elevatePalette == Constants.LEGENDARY || burnPalette == Constants.LEGENDARY)
            revert InvalidElevation(elevateTokenId, burnTokenId);

        // Generate new palette
        uint8 newTier = elevateTier + 1;
        uint8 newPalette = MetadataUtils.calculateElevatedPalette(newTier, globalSeed);

        // Set token palette
        tokenPalettes[elevateTokenId] = newPalette;
        tokenPalettes[burnTokenId] = 0;
        // Set token seed
        tokenSeeds[elevateTokenId] = globalSeed;
        tokenSeeds[burnTokenId] = 0;
        // Update global seed
        globalSeed = Utils.generateNextSeed(globalSeed, elevateTokenId);

        // Emit the event
        emit TokenElevated(elevateTokenId, newPalette, newTier, tokenSeeds[elevateTokenId]);
    }

    /*************************************/
    /*              Private              */
    /*************************************/

    /**
     * @notice Creates the metadata structure for a token
     * @param tokenId The ID of the token to create metadata for
     * @return TokenMetadata structure containing all token metadata
     */
    function _createTokenMetadata(uint256 tokenId) private view returns (TokenMetadata memory) {
        uint8[VALUES_ARRAY_SIZE] memory values = _getValues(tokenId);
        uint8 palette = tokenPalettes[tokenId];
        uint8 tier = MetadataUtils.calculateTierFromPalette(palette);
        return TokenMetadata({ id: tokenId, values: values, palette: palette, tier: tier, animationUrl: animationUrl });
    }

    /**
     * @notice Retrieves the current values for a token
     * @param tokenId The ID of the token to get values for
     * @return Array of values
     */
    function _getValues(uint256 tokenId) private view returns (uint8[VALUES_ARRAY_SIZE] memory) {
        if (LegendaryValues.isLegendary(tokenId)) {
            return LegendaryValues.getLegendaryValues(tokenId).values;
        }
        return valueGenerator.generateValuesFromSeeds(tokenId, tokenSeeds[tokenId]);
    }
}
