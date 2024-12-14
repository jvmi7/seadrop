// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Constants
 * @notice Library containing all constant values used throughout the contract system
 */
library Constants {
    // Time-related constants
    /// @notice Number of seconds in a day (set to 1 for testing purposes)
    uint256 internal constant DAY_IN_SECONDS = 1;

    // Random value generation constants
    /// @notice Maximum value that can be generated (1-100 range)
    uint256 internal constant MAX_RANDOM_VALUE = 100;

    // Palette distribution thresholds
    /// @notice Threshold for Palette 0 (0-8)
    uint256 internal constant PALETTE_0_THRESHOLD = 8;
    /// @notice Threshold for Palette 1 (9-12)
    uint256 internal constant PALETTE_1_THRESHOLD = 12;
    /// @notice Threshold for Palette 2 (13-14)
    uint256 internal constant PALETTE_2_THRESHOLD = 14;
    /// @notice Threshold for Palette 3 (15)
    uint256 internal constant PALETTE_3_THRESHOLD = 15;
    /// @notice Total range for palette distribution (0-16)
    uint256 internal constant TOTAL_DISTRIBUTION_RANGE = 16;

    // NFT metadata constants
    /// @notice Default name for new NFTs
    string internal constant BASE_NAME = "Untitled";
    /// @notice Default description for new NFTs
    string internal constant BASE_DESCRIPTION = "A new NFT";
    /// @notice Prefix used for palette names
    string internal constant PALETTE_PREFIX = "Palette ";
}