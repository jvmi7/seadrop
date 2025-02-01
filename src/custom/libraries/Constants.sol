// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Constants
 * @notice Library containing all constant values used throughout the contract system
 */
library Constants {

    // Time-related constants
    /// @notice Number of seconds in a day (set to 1 for testing purposes)
    uint256 internal constant DEFAULT_INTERVAL = 0;

    // Random value generation constants
    /// @notice Maximum value that can be generated (1-100 range)
    uint256 internal constant MAX_RANDOM_VALUE = 100;
    uint8 internal constant RANDOM_SEED_ARRAY_SIZE = 7;

    /// @notice Palette indices for different color schemes
    uint8 constant REDS = 0;
    uint8 constant YELLOWS = 1;
    uint8 constant GREENS = 2;
    uint8 constant BLUES = 3;
    uint8 constant VIOLETS = 4;
    uint8 constant CHROMATIC = 5;
    uint8 constant PASTEL = 6;
    uint8 constant GREYSCALE = 7;

    // NFT metadata constants
    /// @notice Default description for new NFTs
    string internal constant DESCRIPTION = "charts by jvmi";
    string internal constant ANIMATION_URL = "https://charts-by-jvmi-jet.vercel.app/";
}
