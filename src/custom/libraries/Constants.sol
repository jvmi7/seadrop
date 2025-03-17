// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Constants
 * @notice Library containing all constant values used throughout the contract system
 */
library Constants {
    // Time-related constants
    // @notice Number of seconds in a day (set to 1 for testing purposes)
    uint256 internal constant DEFAULT_INTERVAL = 0;

    // Random value generation constants
    // @notice Maximum value that can be generated (1-100 range)
    uint256 internal constant MAX_RANDOM_VALUE = 100;
    uint8 internal constant RANDOM_SEED_ARRAY_SIZE = 7;

    // @notice Palette indices for different color schemes
    uint8 constant REDS = 1;
    uint8 constant YELLOWS = 2;
    uint8 constant GREENS = 3;
    uint8 constant BLUES = 4;
    uint8 constant VIOLETS = 5;
    uint8 constant RGB = 6;
    uint8 constant CMY = 7;
    uint8 constant WARM = 8;
    uint8 constant COOL = 9;
    uint8 constant CHROMATIC = 10;
    uint8 constant PASTEL = 11;
    uint8 constant GREYSCALE = 12;
    uint8 constant LEGENDARY = 13;

    // @notice Tier indices for different color schemes
    uint8 constant GENESIS_TIER = 1;
    uint8 constant ELEVATED_TIER = 2;
    uint8 constant ULTRA_TIER = 3;
    uint8 constant ELITE_TIER = 4;
    uint8 constant LEGENDARY_TIER = 5;

    // NFT metadata constants
    // @notice Default description for new NFTs
    string internal constant DESCRIPTION =
        "welcome to charts, an interactive art experience challenging how we value price in the NFT space. the collection builds on the swatches by jvmi aesthetic, featuring vibrant colors and aesthetic shapes to introduce a new value system based on charts. alongside the interactive canvas, collectors can burn to create new charts of increasing rarity to elevate their collection.";
    string internal constant ANIMATION_URL = "https://charts-by-jvmi-jet.vercel.app";
    uint8 constant LEGENDARY_CHARTS_COUNT = 16;
}
