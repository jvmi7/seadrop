// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Constants.sol";
import "./LegendaryValues.sol";

/**
 * @title MetadataUtils
 * @notice A utility library for metadata operations
 */
library MetadataUtils {
    /**
     * @notice Calculates the tier for a token based on its palette
     * @param palette The palette of the token
     * @return Tier index (0-4)
     */
    function calculateTierFromPalette(uint8 palette) internal pure returns (uint8) {
        if (
            palette == Constants.REDS ||
            palette == Constants.YELLOWS ||
            palette == Constants.GREENS ||
            palette == Constants.BLUES ||
            palette == Constants.VIOLETS
        ) return Constants.GENESIS_TIER;
        if (
            palette == Constants.RGB ||
            palette == Constants.CMY ||
            palette == Constants.WARM ||
            palette == Constants.COOL
        ) return Constants.RARE_TIER;
        if (palette == Constants.CHROMATIC || palette == Constants.PASTEL) return Constants.SUPER_RARE_TIER;
        if (palette == Constants.GREYSCALE) return Constants.ULTRA_RARE_TIER;
        if (palette == Constants.LEGENDARY) return Constants.LEGENDARY_TIER;
        revert("Invalid palette");
    }

    /**
     * @notice Calculates the palette for a token based on its tokenId
     * @param tokenId The tokenId of the token
     * @return Palette index (0-4)
     */
    function calculateGenesisPalette(uint256 tokenId) internal pure returns (uint8) {
        uint8 mod = uint8(tokenId % 5);
        if (mod == 0) return Constants.REDS;
        if (mod == 1) return Constants.YELLOWS;
        if (mod == 2) return Constants.GREENS;
        if (mod == 3) return Constants.BLUES;
        if (mod == 4) return Constants.VIOLETS;
        revert("Invalid tokenId");
    }

    /**
     * @notice Calculates the next palette for a token based on the tier
     * @param tier The tier of the token
     * @param seed The seed of the token
     * @return The next palette
     */
    function calculateElevatedPalette(uint8 tier, bytes32 seed) internal pure returns (uint8) {
        if (tier == Constants.RARE_TIER) {
            uint8 randomValue = uint8(uint256(keccak256(abi.encodePacked(seed))) % 4);
            if (randomValue == 0) return Constants.RGB;
            if (randomValue == 1) return Constants.CMY;
            if (randomValue == 2) return Constants.WARM;
            if (randomValue == 3) return Constants.COOL;
        }
        if (tier == Constants.SUPER_RARE_TIER) {
            uint8 randomValue = uint8(uint256(keccak256(abi.encodePacked(seed))) % 2);
            if (randomValue == 0) return Constants.CHROMATIC;
            if (randomValue == 1) return Constants.PASTEL;
        }
        if (tier == Constants.ULTRA_RARE_TIER) {
            return Constants.GREYSCALE;
        }
        revert("Invalid tier");
    }

    /**
     * @notice Gets the name of a tier
     * @param tier The tier of the token
     * @return The name of the tier
     */
    function getTierName(uint8 tier) internal pure returns (string memory) {
        if (tier == Constants.GENESIS_TIER) return "genesis";
        if (tier == Constants.RARE_TIER) return "elevated";
        if (tier == Constants.SUPER_RARE_TIER) return "ultra elevated";
        if (tier == Constants.ULTRA_RARE_TIER) return "max elevated";
        if (tier == Constants.LEGENDARY_TIER) return "legendary";
        revert("Invalid tier");
    }

    /**
     * @notice Formats a trait for the token metadata
     * @dev Used for formatting traits in the attributes section
     * @param traitType The type of trait
     * @param value The value of the trait
     * @return Formatted string containing the trait
     */
    function formatAttribute(string memory traitType, string memory value) public pure returns (string memory) {
        return string(abi.encodePacked(',{"trait_type":"', traitType, '","value":"', value, '"}'));
    }
}
