// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Constants
 * @notice Library containing all constant values used throughout the contract system
 */
library Constants {

    // Time-related constants
    /// @notice Number of seconds in a day (set to 1 for testing purposes)
    uint256 internal constant DEFAULT_INTERVAL = 1;

    // Random value generation constants
    /// @notice Maximum value that can be generated (1-100 range)
    uint256 internal constant MAX_RANDOM_VALUE = 100;

    // Palette distribution thresholds
    /// @notice Threshold for Palette 0 (1)
    uint256 internal constant PALETTE_0_THRESHOLD = 1;
    /// @notice Threshold for Palette 1 (2)
    uint256 internal constant PALETTE_1_THRESHOLD = 2;
    /// @notice Threshold for Palette 2 (3)
    uint256 internal constant PALETTE_2_THRESHOLD = 3;
    /// @notice Threshold for Palette 3 (4)
    uint256 internal constant PALETTE_3_THRESHOLD = 4;
    /// @notice Total range for palette distribution (1-4)
    uint256 internal constant TOTAL_DISTRIBUTION_RANGE = 4;

    // NFT metadata constants
    /// @notice Default name for new NFTs
    string internal constant BASE_NAME = "Untitled";
    /// @notice Default description for new NFTs
    string internal constant BASE_DESCRIPTION = "A new NFT";

    // Palette types
    uint8 public constant PALETTE_0 = 0;
    uint8 public constant PALETTE_1 = 1;
    uint8 public constant PALETTE_2 = 2;
    uint8 public constant PALETTE_3 = 3;
    uint8 public constant PALETTE_CHROMATIC = 4;
    uint8 public constant PALETTE_PASTEL = 5;
    uint8 public constant PALETTE_GREYSCALE = 6;
    uint8 public constant TOTAL_PALETTES = 7;

    // Conversion requirements
    uint8 public constant CONVERSION_BATCH_SIZE = 4;
}