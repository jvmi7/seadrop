// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { TokenMetadata } from "./types/MetadataTypes.sol";
import { Constants } from "./libraries/Constants.sol";
import { IValueGenerator } from "./interfaces/IValueGenerator.sol";
import { ArrayUtils } from "./libraries/ArrayUtils.sol";
import { MetadataUtils } from "./libraries/MetadataUtils.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";

/**
 * @title MetadataRenderer
 * @notice Handles the generation and management of NFT metadata, including values and palettes
 * @dev This contract works in conjunction with a value generator
 */
contract MetadataRenderer is IMetadataRenderer {
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
    IValueGenerator public immutable valueGenerator;

    /// @notice Maps token IDs to their color palettes
    mapping(uint256 => uint8) private _tokenPalettes;
    /// @notice Tracks whether a token's values are locked
    mapping(uint256 => bool) private _tokenLocked;
    /// @notice Stores the locked values for tokens
    mapping(uint256 => uint8[VALUES_ARRAY_SIZE]) private _lockedValues;
    /// @notice Tracks whether a token is a special token
    mapping(uint256 => bool) private _isSpecialToken;

    /*************************************/
    /*              Errors               */
    /*************************************/
    error OnlyNFTContract();
    error TokenAlreadyLocked();
    error ValuesNotReadyForLocking(string message);
    error InvalidSpecialPalette();

    /*************************************/
    /*              Constructor          */
    /*************************************/
    /**
     * @notice Initializes the contract with necessary dependencies
     * @param _nftContract Address of the NFT contract
     * @param _valueGenerator Address of the value generator contract
     */
    constructor(
        address _nftContract, 
        address _valueGenerator
    ) {
        nftContract = _nftContract;
        valueGenerator = IValueGenerator(_valueGenerator);
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
     * @notice Checks if a token is marked as special
     * @param tokenId The ID of the token to check
     * @return Boolean indicating if the token is special
     */
    function getIsSpecialToken(uint256 tokenId) external view returns (bool) {
        return _isSpecialToken[tokenId];
    }
    
    /**
     * @notice Gets the number of revealed values for a token
     * @param tokenId The ID of the token to check
     * @return Number of revealed values
     */
    function getRevealedValuesCount(uint256 tokenId) external view returns (uint256) {
        if (!_isSpecialToken[tokenId]) return VALUES_ARRAY_SIZE;
        return valueGenerator.getCurrentIteration() - 
               valueGenerator.getTokenMintIteration(tokenId);
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
     * @notice Sets a token as a special token with a specific palette
     * @param tokenId The ID of the token to set as special
     * @param palette The palette of the special token
     * @dev Only callable by NFT contract and requires special palette range
     */
    function setSpecialToken(uint256 tokenId, uint8 palette) external onlyNFTContract {
        if (palette < Constants.CHROMATIC) revert InvalidSpecialPalette();
        _isSpecialToken[tokenId] = true;
        _tokenPalettes[tokenId] = palette;
        valueGenerator.setTokenMintIteration(tokenId);
    }

    /*************************************/
    /*              External             */
    /*************************************/
    /**
     * @notice Locks a token's values permanently
     * @param tokenId The ID of the token to lock
     * @dev Once locked, a token's values cannot be changed
     */
    function lockTokenValues(uint256 tokenId) external onlyNFTContract {
        if (_tokenLocked[tokenId]) revert TokenAlreadyLocked();
        
        uint8[VALUES_ARRAY_SIZE] memory currentValues = valueGenerator.generateValuesFromSeeds(tokenId);
        if (!currentValues.areAllValuesNonZero()) {
            revert ValuesNotReadyForLocking("Token cannot be locked with unrevealed values");
        }
        
        _tokenLocked[tokenId] = true;
        _lockedValues[tokenId] = currentValues;
        
        emit TokenLocked(tokenId);
    }

    /**
     * @notice Generates the complete token URI for a given token
     * @param tokenId The ID of the token to generate URI for
     * @return The complete token URI as a string
     */
    function generateTokenURI(uint256 tokenId) external view returns (string memory) {        
        TokenMetadata memory metadata = _createTokenMetadata(tokenId);
        return MetadataUtils.generateTokenURI(metadata);
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
            isLocked: _tokenLocked[tokenId]
        });
    }

    /**
     * @notice Retrieves the current values for a token
     * @param tokenId The ID of the token to get values for
     * @return Array of values, either locked or generated
     */
    function _getValues(uint256 tokenId) 
        private 
        view 
        returns (uint8[VALUES_ARRAY_SIZE] memory) 
    {
        return _tokenLocked[tokenId] ? _lockedValues[tokenId] : valueGenerator.generateValuesFromSeeds(tokenId);
    }

    /**
     * @notice Calculates the initial palette for a token based on its ID
     * @param tokenId The ID of the token to calculate palette for
     * @return Palette index (0-3)
     */
    function _calculateInitialPalette(uint256 tokenId) private pure returns (uint8) {
        uint8 mod = uint8(tokenId % (Constants.PUNCH + 1));
        return mod;
    }
}