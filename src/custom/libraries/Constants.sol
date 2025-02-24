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
    uint8 constant RGB = 5;
    uint8 constant CMY = 6;
    uint8 constant CHROMATIC = 7;
    uint8 constant PASTEL = 8;
    uint8 constant GREYSCALE = 9;
    uint8 constant LEGENDARY = 10;

    /// @notice Tier indices for different color schemes
    uint8 constant GENESIS_TIER = 0;
    uint8 constant RARE_TIER = 1;
    uint8 constant SUPER_RARE_TIER = 2;
    uint8 constant ULTRA_RARE_TIER = 3;
    uint8 constant LEGENDARY_TIER = 4;

    // NFT metadata constants
    /// @notice Default description for new NFTs
    string internal constant DESCRIPTION = "charts by jvmi";
    string internal constant ANIMATION_URL = "https://charts-by-jvmi-jet.vercel.app";
    uint8 constant LEGENDARY_CHARTS_COUNT = 16;
}
