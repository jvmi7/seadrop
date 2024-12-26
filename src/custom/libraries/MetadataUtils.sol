// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import "../types/MetadataTypes.sol";
import "../libraries/Constants.sol";
import "../libraries/SVGGenerator.sol";
import "../libraries/Palettes.sol";
import "../libraries/Utils.sol";
import "./ArrayUtils.sol";

/**
 * @title MetadataUtils
 * @notice Handles the generation of token metadata, including JSON formatting and SVG image generation
 * @dev Implemented as a library for gas efficiency and reusability
 */
library MetadataUtils {
    using Strings for uint256;
    using Utils for uint8;
    using ArrayUtils for uint8[7];

    /*************************************/
    /*         Core Token URI            */
    /*************************************/

    /**
     * @notice Main entry point for generating a complete token URI
     * @dev Combines basic properties, attributes, and image data into a base64 encoded JSON
     * @param metadata The token metadata structure containing all necessary information
     * @return A base64 encoded data URI containing the complete token metadata
     */
    function generateTokenURI(TokenMetadata memory metadata) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            generateBasicProperties(metadata),
                            generateAttributesSection(metadata),
                            '}'
                        )
                    )
                )
            )
        );
    }

    /*************************************/
    /*       Metadata Generation         */
    /*************************************/

    /**
     * @notice Generates the basic properties section of the token metadata
     * @dev Includes name, description, image URI, animation URL, and value string
     * @param metadata The token metadata structure
     * @return Formatted string containing the basic token properties
     */
    function generateBasicProperties(TokenMetadata memory metadata) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '"name":"', generateName(metadata.id), '",',
                '"description":"', Constants.DESCRIPTION, '",',
                '"image":"', generateImageURI(metadata.values, metadata.palette), '",',
                '"animation_url":"https://charts-by-jvmi-jet.vercel.app/?values=[', generateValueString(metadata.values), ']&palette=', Palettes.getColorPalette(metadata.palette).name, '",',
                '"values":"', generateValueString(metadata.values), '",'
            )
        );
    }

    /**
     * @notice Generates the attributes section of the token metadata
     * @dev Includes palette name, lock status, and current value
     * @param metadata The token metadata structure
     * @return Formatted string containing the token attributes
     */
    function generateAttributesSection(TokenMetadata memory metadata) 
        internal 
        pure 
        returns (string memory) 
    {
        Palettes.ColorPalette memory palette = Palettes.getColorPalette(metadata.palette);
        return string(
            abi.encodePacked(
                '"attributes":[',
                '{"trait_type":"palette","value":"', palette.name, '"},',
                '{"trait_type":"isLocked","value":"', metadata.isLocked ? 'yes' : 'no', '"},',
                '{"trait_type":"value","value":"', uint256(metadata.values.getLastNonZeroValue()).toString(), '"}',
                ']'
            )
        );
    }

    /*************************************/
    /*         Utility Functions         */
    /*************************************/

    /**
     * @notice Generates the image URI for a token using SVG
     * @dev Combines SVG generation with base64 encoding for on-chain storage
     * @param values The array of values to use in the SVG generation
     * @param palette The palette index to use for colors
     * @return A base64 encoded SVG data URI
     */
    function generateImageURI(
        uint8[7] memory values,
        uint8 palette
    ) 
        internal 
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

    /**
     * @notice Generates the name for a token based on its ID
     * @dev Creates a deterministic but non-sequential name using the format "$ABC-DEF"
     * @param tokenId The ID of the token
     * @return The formatted name string using A-F,X-Z characters
     */
    function generateName(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        bytes memory letters = "ABCDEFXYZ";
        bytes memory result = new bytes(8); // 1 dollar sign + 3 chars + hyphen + 3 chars
        
        // Create a pseudo-random but deterministic number from tokenId
        uint256 hash = uint256(keccak256(abi.encodePacked(tokenId)));
        
        // Add dollar sign and use hash to get deterministic but non-sequential letters
        result[0] = "$";
        result[1] = letters[hash % 9];
        result[2] = letters[(hash / 9) % 9];
        result[3] = letters[(hash / 81) % 9];
        result[4] = "-";
        result[5] = letters[(hash / 729) % 9];
        result[6] = letters[(hash / 6561) % 9];
        result[7] = letters[(hash / 59049) % 9];
        
        return string(result);
    }

    /**
     * @notice Converts an array of values into a comma-separated string
     * @dev Used for storing raw values in token metadata
     * @param values Array of uint8 values to convert
     * @return Comma-separated string of values
     */
    function generateValueString(uint8[7] memory values) 
        internal 
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
}

