// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Constants } from "./Constants.sol";

/**
 * @title LegendaryValues
 * @notice Library containing all legendary token values
 */
library LegendaryValues {
    /*************************************/
    /*              Structs              */
    /*************************************/

    // @notice Structure to hold legendary token data
    // @param values Array of 7 values representing the token's pattern
    // @param name Name of the legendary token
    struct LegendaryData {
        uint8[7] values;
        string name;
    }

    /**
     * @notice Returns the values for a legendary token
     * @param tokenId The ID of the legendary token
     * @return An array of 7 values
     */
    function getLegendaryValues(uint256 tokenId) internal pure returns (LegendaryData memory) {
        // $HIGHER
        if (tokenId == 1) {
            return LegendaryData({ values: [1, 17, 33, 50, 67, 83, 100], name: "$HIGHER" });
        }
        // $LOWER
        if (tokenId == 2) {
            return LegendaryData({ values: [100, 83, 67, 50, 33, 17, 1], name: "$LOWER" });
        }
        // $EXPONENTIAL
        if (tokenId == 3) {
            return LegendaryData({ values: [1, 3, 7, 15, 33, 67, 100], name: "$EXPONENTIAL" });
        }
        // $LOGARITHMIC
        if (tokenId == 4) {
            return LegendaryData({ values: [1, 34, 55, 71, 84, 93, 100], name: "$LOGARITHMIC" });
        }
        // $VOLATILE
        if (tokenId == 5) {
            return LegendaryData({ values: [1, 100, 1, 100, 1, 100, 1], name: "$VOLATILE" });
        }
        // $MOON
        if (tokenId == 6) {
            return LegendaryData({ values: [1, 1, 1, 1, 1, 1, 100], name: "$MOON" });
        }
        // $RUGGED
        if (tokenId == 7) {
            return LegendaryData({ values: [100, 100, 100, 100, 100, 100, 1], name: "$RUGGED" });
        }
        // $HYPE
        if (tokenId == 8) {
            return LegendaryData({ values: [1, 1, 1, 100, 1, 1, 1], name: "$HYPE" });
        }
        // $LOW
        if (tokenId == 9) {
            return LegendaryData({ values: [1, 1, 1, 1, 1, 1, 1], name: "$LOW" });
        }
        // $HUMBLE
        if (tokenId == 10) {
            return LegendaryData({ values: [33, 33, 33, 33, 33, 33, 33], name: "$HUMBLE" });
        }
        // $COMFORTABLE
        if (tokenId == 11) {
            return LegendaryData({ values: [66, 66, 66, 66, 66, 66, 66], name: "$COMFORTABLE" });
        }
        // $RICH
        if (tokenId == 12) {
            return LegendaryData({ values: [100, 100, 100, 100, 100, 100, 100], name: "$RICH" });
        }
        // $VALLEY
        if (tokenId == 13) {
            return LegendaryData({ values: [100, 66, 33, 1, 33, 66, 100], name: "$VALLEY" });
        }
        // $PEAK
        if (tokenId == 14) {
            return LegendaryData({ values: [1, 33, 66, 100, 66, 33, 1], name: "$PEAK" });
        }
        // $MEME
        if (tokenId == 15) {
            return LegendaryData({ values: [1, 100, 67, 33, 15, 7, 1], name: "$MEME" });
        }
        // $TRENCHES
        if (tokenId == 16) {
            return LegendaryData({ values: [2, 8, 4, 6, 10, 4, 2], name: "$TRENCHES" });
        }

        return LegendaryData({ values: [0, 0, 0, 0, 0, 0, 0], name: "" });
    }

    /**
     * @notice Checks if a token is a legendary token
     * @param tokenId The ID of the token
     * @return bool True if the token is a legendary token, false otherwise
     */
    function isLegendary(uint256 tokenId) internal pure returns (bool) {
        return tokenId <= Constants.LEGENDARY_CHARTS_COUNT;
    }
}
