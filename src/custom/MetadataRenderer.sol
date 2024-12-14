// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { TokenMetadata } from "./types/MetadataTypes.sol";
import { Constants } from "./libraries/Constants.sol";
import { IValueGenerator } from "./interfaces/IValueGenerator.sol";
import { IMetadataGenerator } from "./interfaces/IMetadataGenerator.sol";
import { ArrayUtils } from "./libraries/ArrayUtils.sol";

/**
 * @title MetadataRenderer
 * @notice Handles the generation and management of NFT metadata, including values and palettes
 * @dev This contract works in conjunction with a value generator and metadata generator
 */
contract MetadataRenderer {
    using Strings for uint256;
    using ArrayUtils for uint8[7];

    // Constants
    uint256 private constant VALUES_ARRAY_SIZE = 7;

    // State variables
    /// @notice Address of the NFT contract that this renderer serves
    address public immutable nftContract;
    /// @notice Contract that generates the token values
    IValueGenerator public immutable valueGenerator;
    /// @notice Contract that generates the final metadata
    IMetadataGenerator public immutable metadataGenerator;

    // Mappings
    /// @notice Maps token IDs to their color palettes
    mapping(uint256 => uint8) private _tokenPalettes;
    /// @notice Tracks whether a token's values are locked
    mapping(uint256 => bool) private _tokenLocked;
    /// @notice Stores the locked values for tokens
    mapping(uint256 => uint8[VALUES_ARRAY_SIZE]) private _lockedValues;

    // Events
    /// @notice Emitted when a token's metadata is updated
    event MetadataUpdated(uint256 indexed tokenId);
    /// @notice Emitted when a token's values are locked
    event TokenLocked(uint256 indexed tokenId);

    // Errors
    error OnlyNFTContract();
    error TokenAlreadyLocked();
    error ValuesNotReadyForLocking(string message);

    /**
     * @notice Initializes the contract with necessary dependencies
     * @param _nftContract Address of the NFT contract
     * @param _valueGenerator Address of the value generator contract
     * @param _metadataGenerator Address of the metadata generator contract
     */
    constructor(
        address _nftContract, 
        address _valueGenerator,
        address _metadataGenerator
    ) {
        nftContract = _nftContract;
        valueGenerator = IValueGenerator(_valueGenerator);
        metadataGenerator = IMetadataGenerator(_metadataGenerator);
    }

    /// @notice Ensures only the NFT contract can call certain functions
    modifier onlyNFTContract() {
        if (msg.sender != nftContract) revert OnlyNFTContract();
        _;
    }

    /**
     * @notice Sets the initial metadata for a newly minted token
     * @param tokenId The ID of the token to set metadata for
     */
    function setInitialMetadata(uint256 tokenId) external onlyNFTContract {
        _tokenPalettes[tokenId] = _calculateInitialPalette(tokenId);
    }

    /**
     * @notice Locks a token's values permanently
     * @param tokenId The ID of the token to lock
     * @dev Once locked, a token's values cannot be changed
     */
    function lockTokenValues(uint256 tokenId) external onlyNFTContract {
        if (_tokenLocked[tokenId]) revert TokenAlreadyLocked();
        
        uint8[VALUES_ARRAY_SIZE] memory currentValues = valueGenerator.generateValuesFromSeeds(tokenId);
        if (!currentValues.areAllValuesNonZero()) {
            revert ValuesNotReadyForLocking("Token values are not yet complete. Please wait for daily updates to generate all values before locking.");
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
        return metadataGenerator.generateTokenURI(metadata);
    }

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
            name: metadataGenerator.generateName(tokenId),
            description: Constants.BASE_DESCRIPTION,
            image: metadataGenerator.generateImageURI(
                values,
                _tokenPalettes[tokenId]
            ),
            animationUrl: "",
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
        uint256 mod16 = tokenId % Constants.TOTAL_DISTRIBUTION_RANGE;
        
        if (mod16 < Constants.PALETTE_0_THRESHOLD) return 0;
        if (mod16 < Constants.PALETTE_1_THRESHOLD) return 1;
        if (mod16 < Constants.PALETTE_2_THRESHOLD) return 2;
        if (mod16 < Constants.PALETTE_3_THRESHOLD) return 3;
        return 0;
    }
}