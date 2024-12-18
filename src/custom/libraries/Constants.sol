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
    uint8 internal constant RANDOM_SEED_ARRAY_SIZE = 7;

    /// @notice Palette indices for different color schemes
    uint8 constant CLASSIC = 0;
    uint8 constant ICE = 1;
    uint8 constant FIRE = 2;
    uint8 constant PUNCH = 3;
    uint8 constant CHROMATIC = 4;
    uint8 constant PASTEL = 5;
    uint8 constant GREYSCALE = 6;

    // NFT metadata constants
    /// @notice Default description for new NFTs
    string internal constant DESCRIPTION = "charts by jvmi";
}