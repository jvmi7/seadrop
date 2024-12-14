// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import "../interfaces/IMetadataGenerator.sol";
import "../types/MetadataTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/SVGGenerator.sol";

/**
 * @title MetadataGenerator
 * @notice Handles the generation of token metadata, including JSON formatting and SVG image generation
 * @dev Implements IMetadataGenerator interface to provide standardized metadata generation
 */
contract MetadataGenerator is IMetadataGenerator {
    using Strings for uint256;

    /**
     * @notice Generates the complete token URI with base64 encoded metadata
     * @param metadata The token metadata structure containing all necessary information
     * @return A base64 encoded data URI containing the complete token metadata
     */
    function generateTokenURI(TokenMetadata memory metadata) 
        external 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        generateJSONMetadata(metadata)
                    )
                )
            )
        );
    }

    /**
     * @notice Generates the JSON metadata string from the token metadata
     * @param metadata The token metadata structure
     * @return A properly formatted JSON string containing all metadata
     */
    function generateJSONMetadata(TokenMetadata memory metadata) 
        public 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '{',
                generateBasicProperties(metadata),
                generateAttributesSection(metadata),
                '}'
            )
        );
    }

    /**
     * @notice Generates the basic properties section of the JSON metadata
     * @param metadata The token metadata structure
     * @return A string containing the basic token properties in JSON format
     */
    function generateBasicProperties(TokenMetadata memory metadata) 
        public 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '"name":"', metadata.name, '",',
                '"description":"', metadata.description, '",',
                '"image":"', metadata.image, '",',
                '"animation_url":"', metadata.animationUrl, '",',
                '"values":"', generateValueString(metadata.values), '",'
            )
        );
    }

    /**
     * @notice Generates the attributes section of the JSON metadata
     * @param metadata The token metadata structure
     * @return A string containing the token attributes in JSON format
     */
    function generateAttributesSection(TokenMetadata memory metadata) 
        public 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '"attributes":[',
                _generateAttributes(metadata),
                ']'
            )
        );
    }

    /**
     * @notice Converts an array of values into a comma-separated string
     * @param values Array of uint8 values to convert
     * @return A comma-separated string of values
     */
    function generateValueString(uint8[7] memory values) 
        public 
        pure 
        returns (string memory) 
    {
        string memory result = "";
        for (uint256 i = 0; i < 7; i++) {
            if (i > 0) result = string(abi.encodePacked(result, ","));
            result = string(abi.encodePacked(result, uint256(values[i]).toString()));
        }
        return result;
    }

    /**
     * @notice Generates the attributes array for the token metadata
     * @param metadata The token metadata structure
     * @return A JSON string containing the token's attributes
     */
    function _generateAttributes(TokenMetadata memory metadata) 
        private 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '{"trait_type":"palette","value":"', _getPaletteName(metadata.palette), '"},',
                '{"trait_type":"isLocked","value":"', metadata.isLocked ? 'yes' : 'no', '"},',
                '{"trait_type":"value","value":"', uint256(_getLastNonZeroValue(metadata.values)).toString(), '"}'
            )
        );
    }

    /**
     * @notice Generates the palette name string
     * @param palette The palette index
     * @return The formatted palette name string
     */
    function _getPaletteName(uint8 palette) private pure returns (string memory) {
        return string(abi.encodePacked(Constants.PALETTE_PREFIX, uint256(palette).toString()));
    }

    /**
     * @notice Finds the last non-zero value in the values array
     * @param values Array of values to search through
     * @return The last non-zero value found, or 0 if none exists
     */
    function _getLastNonZeroValue(uint8[7] memory values) 
        private 
        pure 
        returns (uint8) 
    {
        uint8 lastValue = 0;
        for (uint256 i = 0; i < 7; i++) {
            if (values[i] != 0) {
                lastValue = values[i];
            }
        }
        return lastValue;
    }

    /**
     * @notice Generates the name for a token based on its ID
     * @param tokenId The ID of the token
     * @return The formatted name string
     */
    function generateName(uint256 tokenId) 
        public 
        pure 
        returns (string memory) 
    {
        return string(abi.encodePacked(Constants.BASE_NAME, " #", tokenId.toString()));
    }

    /**
     * @notice Generates the image URI for a token using SVG
     * @param values The array of values to use in the SVG
     * @param palette The palette index to use
     * @return A base64 encoded SVG data URI
     */
    function generateImageURI(
        uint8[7] memory values,
        uint8 palette
    ) 
        public 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                SVGGenerator.generateSVG(
                    values,
                    palette
                )
            )
        );
    }
}
