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
    
    /// @notice Maps token IDs to their color palettes
    mapping(uint256 => uint8) private _tokenPalettes;

    /*************************************/
    /*              Errors               */
    /*************************************/
    error OnlyNFTContract();
    error InvalidElevatedPalette();

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
     * @notice Checks if a token is marked as elevated
     * @param tokenId The ID of the token to check
     * @return Boolean indicating if the token is elevated
     */
    function getIsElevatedToken(uint256 tokenId) external view returns (bool) {
        uint8 palette = _tokenPalettes[tokenId];
        return palette == Constants.CHROMATIC || palette == Constants.PASTEL || palette == Constants.GREYSCALE;
    }

    /**
     * @notice Gets the animation URL
     * @return The animation URL
     */
    function getAnimationUrl() external view returns (string memory) {
        return animationUrl;
    }

    /*************************************/
    /*              Setters              */
    /*************************************/
    /**
     * @notice Sets the initial metadata for a newly minted token
     * @param tokenId The ID of the token to set metadata for
     */
    function setInitialMetadata(uint256 tokenId) external onlyNFTContract {
        _tokenPalettes[tokenId] = _calculateInitialPalette(tokenId);
    }

    /**
     * @notice Sets a token as an elevated token with a specific palette
     * @param tokenId The ID of the token to set as elevated
     * @param palette The palette of the elevated token
     * @dev Only callable by NFT contract and requires elevated palette range
     */
    function setElevatedToken(uint256 tokenId, uint8 palette, bytes32 seed) external onlyNFTContract {
        if (palette < Constants.CHROMATIC || palette > Constants.GREYSCALE) revert InvalidElevatedPalette();
        _tokenPalettes[tokenId] = palette;
        valueGenerator.updateStateOnElevate(tokenId, seed);
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
        return TokenMetadata({
            id: tokenId,
            values: values,
            palette: _tokenPalettes[tokenId],
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
        return valueGenerator.generateValuesFromSeeds(tokenId);
    }

    /**
     * @notice Calculates the initial palette for a token based on its ID
     * @param tokenId The ID of the token to calculate palette for
     * @return Palette index (0-4)
     */
    function _calculateInitialPalette(uint256 tokenId) private pure returns (uint8) {
        if (LegendaryValues.isLegendary(tokenId)) {
            return Constants.LEGENDARY;
        }
        uint8 mod = uint8(tokenId % 5);
        return mod;
    }
}
