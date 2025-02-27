// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./libraries/PatternUtils.sol";
import "./interfaces/IMetadataPatterns.sol";

/**
 * @title MetadataPatterns
 * @notice Handles the generation of patterns for the charts collection
 */

contract MetadataPatterns is IMetadataPatterns {
    /*************************************/
    /*             Getters               */
    /*************************************/

    /**
     * @notice Returns the pattern for the given values
     * @param values The values to get the pattern for
     * @return The pattern for the given values
     */
    function getPattern(uint8[7] memory values) external pure returns (string memory) {
        return PatternUtils.getPattern(values);
    }

    /**
     * @notice Returns the trend for the given values
     * @param values The values to get the trend for
     * @return The trend for the given values
     */
    function getTrend(uint8[7] memory values) external pure returns (string memory) {
        return PatternUtils.getTrend(values);
    }
}
