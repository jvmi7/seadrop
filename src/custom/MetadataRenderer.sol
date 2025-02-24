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
 * @notice Handles the generation and management of NFT metadata, including values and palettes
 * @dev This contract works in conjunction with a value generator
 */
contract MetadataRenderer is IMetadataRenderer, Ownable {
    using Strings for uint256;
    using ArrayUtils for uint8[7];

    /*************************************/
    /*              Constants            */
    /*************************************/
    /// @notice Size of the values array for each token
    uint256 private constant VALUES_ARRAY_SIZE = 7;

    /*************************************/
    /*              Storage              */
    /*************************************/
    /// @notice Address of the NFT contract that this renderer serves
    address public immutable nftContract;
    /// @notice Contract that generates the token values
    IValueGenerator public valueGenerator;
    /// @notice Contract that implements the metadata generation logic
    MetadataImplementation public metadataImplementation;
    /// @notice URL for the animation
    string public animationUrl;
    /// @notice rolling seed for the value generator
    bytes32 public globalSeed;

    /// @notice Maps token IDs to their color palettes
    mapping(uint256 => uint8) private _tokenPalettes;
    /// @notice Maps token IDs to their seeds
    mapping(uint256 => bytes32) private _tokenSeeds;

    /*************************************/
    /*              Errors               */
    /*************************************/
    error OnlyNFTContract();
    error InvalidElevatedPalette();
    error InvalidElevation();

    /*************************************/
    /*              Constructor          */
    /*************************************/
    /**
     * @notice Initializes the contract with necessary dependencies
     * @param _nftContract Address of the NFT contract
     * @param _valueGenerator Address of the value generator contract
     * @param _metadataImplementation Address of the MetadataImplementation contract
     */
    constructor(
        address _nftContract, 
        address _valueGenerator,
        address _metadataImplementation
    ) {
        nftContract = _nftContract;
        valueGenerator = IValueGenerator(_valueGenerator);
        metadataImplementation = MetadataImplementation(_metadataImplementation);
        animationUrl = Constants.ANIMATION_URL;
        globalSeed = Utils.getNewRandomSeed();
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
     * @notice Gets the palette of a token
     * @param tokenId The ID of the token to get the palette for
     * @return The palette of the token
     */
    function getTokenPalette(uint256 tokenId) external view returns (uint8) {
        return _tokenPalettes[tokenId];
    }

    /**
     * @notice Gets the seed of a token
     * @param tokenId The ID of the token to get the seed for
     * @return The seed of the token
     */
    function getTokenSeed(uint256 tokenId) external view returns (bytes32) {
        return _tokenSeeds[tokenId];
    }

    /*************************************/
    /*              Setters              */
    /*************************************/
    /**
     * @notice Sets the initial metadata for a newly minted token
     * @param tokenId The ID of the token to set metadata for
     */
    function initializeTokenMetadata(uint256 tokenId) external onlyNFTContract {
        if (LegendaryValues.isLegendary(tokenId)) {
            _tokenPalettes[tokenId] = Constants.LEGENDARY;
        } else {
            uint8 palette = MetadataUtils.calculateGenesisPalette(tokenId);
            _tokenPalettes[tokenId] = palette;
        }
    }

    /**
     * @notice Sets the animation URL
     * @param _animationUrl The new animation URL
     */
    function setAnimationUrl(string memory _animationUrl) external onlyOwner {
        animationUrl = _animationUrl;
    }

    /**
     * @notice Sets the address of the MetadataImplementation contract
     * @param _metadataImplementation The new address of the MetadataImplementation contract
     * @dev Only callable by the contract owner
     */
    function setMetadataImplementation(address _metadataImplementation) external onlyOwner {
        metadataImplementation = MetadataImplementation(_metadataImplementation);
    }

    /**
     * @notice Sets the address of the ValueGenerator contract
     * @param _valueGenerator The new address of the ValueGenerator contract
     * @dev Only callable by the contract owner
     */
    function setValueGenerator(address _valueGenerator) external onlyOwner {
        valueGenerator = IValueGenerator(_valueGenerator);
    }

    /*************************************/
    /*              External             */
    /*************************************/
    /**
     * @notice Generates the complete token URI for a given token
     * @param tokenId The ID of the token to generate URI for
     * @return The complete token URI as a string
     */
    function generateTokenURI(uint256 tokenId) external view returns (string memory) {        
        TokenMetadata memory metadata = _createTokenMetadata(tokenId);
        return metadataImplementation.generateTokenURI(metadata);
    }

    /**
     * @notice Elevates a token by burning another token and setting the palette to the next tier
     * @param elevateTokenId The ID of the token to elevate
     * @param burnTokenId The ID of the token to burn
     * @dev Only callable by NFT contract and requires elevated palette range
     */
    function elevate(uint256 elevateTokenId, uint256 burnTokenId) external onlyNFTContract {
        // Validate the tokens are able to be elevated
        uint8 elevatePalette = _tokenPalettes[elevateTokenId];
        uint8 burnPalette = _tokenPalettes[burnTokenId];
        uint8 elevateTier = MetadataUtils.calculateTierFromPalette(elevatePalette);
        uint8 burnTier = MetadataUtils.calculateTierFromPalette(burnPalette);

        // Must be the same tier
        if (elevateTier != burnTier) revert InvalidElevation();
        // Cannot elevate greyscale
        if (elevatePalette == Constants.GREYSCALE || burnPalette == Constants.GREYSCALE) revert InvalidElevatedPalette();
        // Cannot elevate legendary
        if (elevatePalette == Constants.LEGENDARY || burnPalette == Constants.LEGENDARY) revert InvalidElevatedPalette();

        // Generate new palette
        uint8 newTier = elevateTier + 1;
        uint8 newPalette = MetadataUtils.calculateElevatedPalette(newTier, globalSeed);

        // Set token palette
        _tokenPalettes[elevateTokenId] = newPalette;
        // Set token seed
        _tokenSeeds[elevateTokenId] = globalSeed;
        // Update global seed
        globalSeed = Utils.getNewRandomSeed();

        // Emit the event
        emit TokenElevated(elevateTokenId, newPalette, newTier, _tokenSeeds[elevateTokenId]);
    }

    /*************************************/
    /*              Private              */
    /*************************************/
    /**
     * @notice Creates the metadata structure for a token
     * @param tokenId The ID of the token to create metadata for
     * @return TokenMetadata structure containing all token metadata
     */
    function _createTokenMetadata(uint256 tokenId) 
        private 
        view 
        returns (TokenMetadata memory) 
    {
        uint8[VALUES_ARRAY_SIZE] memory values = _getValues(tokenId);
        uint8 palette = _tokenPalettes[tokenId];
        uint8 tier = MetadataUtils.calculateTierFromPalette(palette);
        return TokenMetadata({
            id: tokenId,
            values: values,
            palette: palette,
            tier: tier,
            animationUrl: animationUrl
        });
    }

    /**
     * @notice Retrieves the current values for a token
     * @param tokenId The ID of the token to get values for
     * @return Array of values
     */
    function _getValues(uint256 tokenId) 
        private 
        view 
        returns (uint8[VALUES_ARRAY_SIZE] memory) 
    {
        if (LegendaryValues.isLegendary(tokenId)) {
            return LegendaryValues.getLegendaryValues(tokenId).values;
        }
        return valueGenerator.generateValuesFromSeeds(tokenId, _tokenSeeds[tokenId]);
    }
}
