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
      if (palette == Constants.REDS || palette == Constants.YELLOWS || palette == Constants.GREENS || palette == Constants.BLUES || palette == Constants.VIOLETS) return Constants.GENESIS_TIER;
      if (palette == Constants.RGB || palette == Constants.CMY) return Constants.RARE_TIER;
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
        uint8 randomValue = uint8(uint256(keccak256(abi.encodePacked(seed))) % 2);

        if (tier == Constants.RARE_TIER) {
            return randomValue == 0 ? Constants.RGB : Constants.CMY;
        }
        if (tier == Constants.SUPER_RARE_TIER) {
            return randomValue == 0 ? Constants.CHROMATIC : Constants.PASTEL;
        }
        if (tier == Constants.ULTRA_RARE_TIER) {
            return Constants.GREYSCALE;
        }
        revert("Invalid tier");
    }
}