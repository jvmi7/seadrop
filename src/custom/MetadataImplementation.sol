// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import "./types/MetadataTypes.sol";
import "./libraries/Constants.sol";
import "./libraries/SVGGenerator.sol";
import "./libraries/Palettes.sol";
import "./libraries/ArrayUtils.sol";
import "./libraries/VolatilityUtils.sol";
import "./libraries/Utils.sol";
import "./libraries/MetadataUtils.sol";
import "./libraries/LegendaryValues.sol";
import "./interfaces/IMetadataBadges.sol";
import "./interfaces/IMetadataPatterns.sol";

/**
 * @title MetadataImplementation
 * @notice Handles the generation of token metadata for the charts collection
 */
contract MetadataImplementation is Ownable {
    using Strings for uint256;
    using Utils for uint8;
    using ArrayUtils for uint8[7];

    /*************************************/
    /*              Storage              */
    /*************************************/

    // @notice Address of the metadata badges contract
    address public metadataBadges;
    address public metadataPatterns;

    /*************************************/
    /*              Errors               */
    /*************************************/

    // @notice Thrown when the metadata badges contract is not set
    error MetadataBadgesNotSet();
    // @notice Thrown when the metadata patterns contract is not set
    error MetadataPatternsNotSet();

    /**
     * @notice Constructor to set the initial address of the metadata badges contract
     * @param _metadataBadges The address of the metadata badges contract
     */
    constructor(address _metadataBadges, address _metadataPatterns) {
        metadataBadges = _metadataBadges;
        metadataPatterns = _metadataPatterns;
    }

    /**
     * @notice Sets the address of the metadata badges contract
     * @dev Can only be called by the contract owner
     * @param _metadataBadges The address of the metadata badges contract
     */
    function setMetadataBadges(address _metadataBadges) external onlyOwner {
        metadataBadges = _metadataBadges;
    }

    function setMetadataPatterns(address _metadataPatterns) external onlyOwner {
        metadataPatterns = _metadataPatterns;
    }

    /*************************************/
    /*             Getters               */
    /*************************************/

    /**
     * @notice Main entry point for generating a complete token URI
     * @dev Combines basic properties, attributes, and image data into a base64 encoded JSON
     * @param metadata The token metadata structure containing all necessary information
     * @return A base64 encoded data URI containing the complete token metadata
     */
    function generateTokenURI(TokenMetadata memory metadata) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                generateBasicProperties(metadata),
                                generateAttributesSection(metadata),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*************************************/
    /*              Helpers              */
    /*************************************/

    /**
     * @notice Generates the basic properties section of the token metadata
     * @param metadata The token metadata structure
     * @return Formatted string containing the basic token properties
     */
    function generateBasicProperties(TokenMetadata memory metadata) internal pure returns (string memory) {
        string memory image = SVGGenerator.generateSVG(metadata.values, metadata.palette);

        string memory values = concatenateValues(metadata.values);

        string memory animationUrl = string(
            abi.encodePacked(
                metadata.animationUrl,
                "/?values=[",
                values,
                "]&palette=",
                Palettes.getColorPalette(metadata.palette).name
            )
        );

        return
            string(
                abi.encodePacked(
                    '"name":"',
                    generateName(metadata.id),
                    '","description":"',
                    Constants.DESCRIPTION,
                    '","image":"',
                    image,
                    '","animation_url":"',
                    animationUrl,
                    '","values":"[',
                    values,
                    ']",'
                )
            );
    }

    /**
     * @notice Generates the attributes section of the token metadata
     * @param metadata The token metadata structure
     * @return Formatted string containing the token attributes
     */
    function generateAttributesSection(TokenMetadata memory metadata) internal view returns (string memory) {
        // Ensure the metadataBadges address is set
        if (metadataBadges == address(0)) {
            revert MetadataBadgesNotSet();
        }
        if (metadataPatterns == address(0)) {
            revert MetadataPatternsNotSet();
        }

        IMetadataBadges metadataBadgesContract = IMetadataBadges(metadataBadges);
        IMetadataPatterns metadataPatternsContract = IMetadataPatterns(metadataPatterns);

        Palettes.ColorPalette memory palette = Palettes.getColorPalette(metadata.palette);
        string memory traits;

        // First trait (no comma needed)
        traits = string(abi.encodePacked('{"trait_type":"[ palette ]","value":"', palette.name, '"}'));

        // Tier trait
        traits = string(
            abi.encodePacked(
                traits,
                MetadataUtils.formatAttribute("[ tier ]", MetadataUtils.getTierName(metadata.tier))
            )
        );

        // Conditional traits based on first value
        if (metadata.values[0] != 0) {
            traits = string(
                abi.encodePacked(
                    traits,
                    string(
                        abi.encodePacked(
                            ',{"trait_type":"value","value":',
                            uint256(metadata.values.getLastNonZeroValue()).toString(),
                            "}"
                        )
                    )
                )
            );
        }

        // Conditional traits based on second value
        if (metadata.values[1] != 0) {
            traits = string(
                abi.encodePacked(
                    traits,
                    MetadataUtils.formatAttribute(" [ trend ]", metadataPatternsContract.getTrend(metadata.values))
                )
            );
        }

        // Conditional traits based on last value
        if (metadata.values[6] != 0) {
            traits = string(
                abi.encodePacked(
                    traits,
                    MetadataUtils.formatAttribute(" [ volatility ]", VolatilityUtils.getVolatility(metadata.values)),
                    MetadataUtils.formatAttribute(" [ pattern ]", metadataPatternsContract.getPattern(metadata.values))
                )
            );
        }

        // Badges traits
        traits = string(abi.encodePacked(traits, metadataBadgesContract.generateBadges(metadata)));

        // Wrap in attributes array
        return string(abi.encodePacked('"attributes":[', traits, "]"));
    }

    /**
     * @notice Generates the name for a token based on its ID
     * @dev Creates a deterministic but non-sequential name using the format "$ABC-DEF"
     * @param tokenId The ID of the token
     * @return The formatted name string using non-vowel characters
     */
    function generateName(uint256 tokenId) internal pure returns (string memory) {
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
            result[1 + i] = letters[(hash / (21 ** i)) % 21];
        }

        // Add hyphen
        result[1 + leftLength] = "-";

        // Generate right side characters
        for (uint8 i = 0; i < rightLength; i++) {
            result[2 + leftLength + i] = letters[(hash / (21 ** (i + leftLength))) % 21];
        }

        return string(result);
    }

    function concatenateValues(uint8[7] memory values) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    uint256(values[0]).toString(),
                    ",",
                    uint256(values[1]).toString(),
                    ",",
                    uint256(values[2]).toString(),
                    ",",
                    uint256(values[3]).toString(),
                    ",",
                    uint256(values[4]).toString(),
                    ",",
                    uint256(values[5]).toString(),
                    ",",
                    uint256(values[6]).toString()
                )
            );
    }
}
