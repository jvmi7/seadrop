// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import "./types/MetadataTypes.sol";
import "./libraries/Constants.sol";
import "./libraries/SVGGenerator.sol";
import "./libraries/Palettes.sol";
import "./libraries/Utils.sol";
import "./libraries/ArrayUtils.sol";
import "./libraries/VolatilityUtils.sol";
import "./libraries/PatternUtils.sol";
import "./libraries/BadgeUtils.sol";
import "./libraries/LegendaryValues.sol";

/**
 * @title MetadataImplementation
 * @notice Handles the generation of token metadata, including JSON formatting and SVG image generation
 * @dev Implemented as a contract for stateful operations
 */
contract MetadataImplementation {
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
        public 
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
        public 
        pure 
        returns (string memory) 
    {

        string memory image = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                SVGGenerator.generateSVG(
                    metadata.values,
                    metadata.palette
                )
            )
        );

        string memory animationUrl = string(
            abi.encodePacked(
                metadata.animationUrl,
                '/?values=[', generateValueString(metadata.values), ']&palette=', Palettes.getColorPalette(metadata.palette).name
            )
        );

        return string(
            abi.encodePacked(
                '"name":"', generateName(metadata.id), '",',
                '"description":"', Constants.DESCRIPTION, '",',
                '"image":"', image, '",',
                '"animation_url":"', animationUrl, '",',
                '"values":"[', generateValueString(metadata.values), ']",'
            )
        );
    }

    /**
     * @notice Generates the attributes section of the token metadata
     * @dev Includes palette name and current value
     * @param metadata The token metadata structure
     * @return Formatted string containing the token attributes
     */
    function generateAttributesSection(TokenMetadata memory metadata) 
        public 
        pure 
        returns (string memory) 
    {
        Palettes.ColorPalette memory palette = Palettes.getColorPalette(metadata.palette);
        string memory traits;

        // First trait (no comma needed)
        traits = string(
            abi.encodePacked(
                '{"trait_type":"[ palette ]","value":"',
                palette.name,
                '"}'
            )
        );

        // Conditional traits based on first value
        if (metadata.values[0] != 0) {
            traits = string(abi.encodePacked(
                traits,
                string(
                    abi.encodePacked(
                        ',{"trait_type":"value","value":',
                        uint256(metadata.values.getLastNonZeroValue()).toString(),
                        '}'
                    )
                )
            ));
        }

        // Conditional traits based on second value
        if (metadata.values[1] != 0) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait(" [ trend ]", PatternUtils.getTrend(metadata.values))
            ));
        }

        // Conditional traits based on last value
        if (metadata.values[6] != 0) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait(" [ volatility ]", VolatilityUtils.getVolatility(metadata.values)),
                _formatTrait(" [ pattern ]", PatternUtils.getPattern(metadata.values))
            ));
        }

        // Conditional traits based on badges
        if (BadgeUtils.isHighRoller(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("high roller", "everything above 50")
            ));
        }

        if (BadgeUtils.isLowStakes(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("low stakes", "everything below 50")
            ));
        }

        if (BadgeUtils.isRugged(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("rugged", "got rekt on the last day")
            ));
        }

        if (BadgeUtils.isBlackSwan(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("black swan", "has a huge drop")
            ));
        }

        if (BadgeUtils.isMoon(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("moon", "has a huge spike")
            ));
        }

        if (BadgeUtils.isComeback(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("comeback", "went low but ended high")
            ));
        }

        if (BadgeUtils.isRagsToRiches(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("rags to riches", "started low but ended high")
            ));
        }

        if (BadgeUtils.isFumbled(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("fumbled", "started high but ended low")
            ));
        }

        if (BadgeUtils.isSpike(metadata.values)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("spike", "one day is significantly higher than the rest")
            ));
        }

        if (BadgeUtils.isSymmetrical(metadata.values, metadata.palette)) {
            traits = string(abi.encodePacked(
                traits,
                _formatTrait("symmetrical", "a mirror image")
            ));
        }

        // Wrap in attributes array
        return string(
            abi.encodePacked(
                '"attributes":[',
                traits,
                ']'
            )
        );
    }

    /**
     * @notice Converts an array of values into a comma-separated string
     * @dev Used for storing raw values in token metadata
     * @param values Array of uint8 values to convert
     * @return Comma-separated string of values
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

    /*************************************/
    /*         Utility Functions         */
    /*************************************/

    /**
     * @notice Generates the name for a token based on its ID
     * @dev Creates a deterministic but non-sequential name using the format "$ABC-DEF"
     * @param tokenId The ID of the token
     * @return The formatted name string using non-vowel characters
     */
    function generateName(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        if (LegendaryValues.isLegendary(tokenId)) {
            return LegendaryValues.getLegendaryValues(tokenId).name;
        }

        bytes memory letters = "BCDFGHJKLMNPQRSTVWXYZ"; // All non-vowel characters
        uint256 hash = uint256(keccak256(abi.encodePacked(tokenId)));
        
        // Determine the number of characters on each side (2 to 4)
        uint8 leftLength = uint8((hash % 3) + 2); // 2 to 4
        uint8 rightLength = uint8(((hash / 3) % 3) + 2); // 2 to 4

        bytes memory result = new bytes(1 + leftLength + 1 + rightLength); // 1 dollar sign + left chars + hyphen + right chars
        
        // Add dollar sign
        result[0] = "$";
        
        // Generate left side characters
        for (uint8 i = 0; i < leftLength; i++) {
            result[1 + i] = letters[(hash / (21**i)) % 21];
        }
        
        // Add hyphen
        result[1 + leftLength] = "-";
        
        // Generate right side characters
        for (uint8 i = 0; i < rightLength; i++) {
            result[2 + leftLength + i] = letters[(hash / (21**(i + leftLength))) % 21];
        }
        
        return string(result);
    }

    /*************************************/
    /*         Helper Functions          */
    /*************************************/

    /**
     * @notice Formats a trait for the token metadata
     * @dev Used for formatting traits in the attributes section
     * @param traitType The type of trait
     * @param value The value of the trait
     * @return Formatted string containing the trait
     */
    function _formatTrait(
        string memory traitType,
        string memory value
    ) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                ',{"trait_type":"',
                traitType,
                '","value":"',
                value,
                '"}'
                )
        );
    }
}

