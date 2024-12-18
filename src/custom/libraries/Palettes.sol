// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Constants } from "./Constants.sol";

/**
 * @title Palettes Library
 * @notice Defines color palettes and conversion rules for SVG generation
 * @dev This library maintains constant color definitions and conversion logic
 *      for different visual styles of token representation
 */
library Palettes {
    /*************************************/
    /*              Constants            */
    /*************************************/
    /// @notice Default background color (Black)
    string constant BACKGROUND = "#000000";

    /// @notice Default surface color (Dark grey)
    string constant SURFACE = "#0e0e0e";

    /// @notice Palette indices for different color schemes
    uint8 constant CLASSIC = Constants.CLASSIC;
    uint8 constant ICE = Constants.ICE;
    uint8 constant FIRE = Constants.FIRE;
    uint8 constant PUNCH = Constants.PUNCH;
    uint8 constant CHROMATIC = Constants.CHROMATIC;
    uint8 constant PASTEL = Constants.PASTEL;
    uint8 constant GREYSCALE = Constants.GREYSCALE;

    /// @notice Special value indicating all base palettes are required
    uint8 constant ALL_BASE_PALETTES = type(uint8).max;

    /*************************************/
    /*              Structs              */
    /*************************************/
    /// @notice Structure to hold color information for the SVG
    /// @param name Name of the palette
    /// @param background Background color of the entire SVG
    /// @param surface Color of the main surface/container
    /// @param barColors Array of colors for the bars
    struct ColorPalette {
        string name;
        string background;
        string surface;
        string[7] barColors;
    }

    /// @notice Defines the rules for palette conversions
    /// @param requiredPalette Palette that must be owned to unlock this one
    /// @param resultPalette The palette that will be unlocked
    /// @param requiredTokenCount Number of tokens needed for conversion
    struct PaletteConversion {
        uint8 requiredPalette;
        uint8 resultPalette;
        uint8 requiredTokenCount;
    }

    /*************************************/
    /*              Errors               */
    /*************************************/
    /// @notice Thrown when an invalid palette index is provided
    error InvalidPalette(uint8 paletteIndex, string message);

    /*************************************/
    /*              Internal             */
    /*************************************/
    /// @notice Returns a color palette based on the provided index
    /// @param paletteIndex Index of the desired color palette (0-6)
    /// @return ColorPalette The selected color scheme
    function getColorPalette(uint8 paletteIndex) internal pure returns (ColorPalette memory) {
        if (paletteIndex == CLASSIC) {
            return ColorPalette({
                name: "Classic",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#ff7700", "#ffb200", "#fff000", "#BFF300", "#80F700", "#40FB00", "#00ff00"]
            });
        }
        if (paletteIndex == ICE) {
            return ColorPalette({
                name: "Ice",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#5000FB", "#2849FD", "#0092FF", "#00AEFF", "#00C9FF", "#00E4FF", "#00FFFF"]
            });
        }
        if (paletteIndex == FIRE) {
            return ColorPalette({
                name: "Fire",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF1D00", "#FF5700", "#FF7200", "#FF8D00", "#FFA700", "#FFC200", "#FFDD00"]
            });
        }
        if (paletteIndex == PUNCH) {
            return ColorPalette({
                name: "Punch",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#6F00FF", "#9B00FF", "#C600FF", "#F200FF", "#F600AA", "#FB0080", "#FF0056"]
            });
        }
        if (paletteIndex == CHROMATIC) {
            return ColorPalette({
                name: "Chromatic",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF0000", "#FF6200", "#FFE300", "#00FF00", "#00CFFF", "#6F00FF", "#F200FF"]
            });
        }
        if (paletteIndex == PASTEL) {
            return ColorPalette({
                name: "Pastel",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF8080", "#FCAD81", "#FFEC7D", "#78FF78", "#7EEAFC", "#AE7BFF", "#F680FF"]
            });
        } if (paletteIndex == GREYSCALE) {  
            return ColorPalette({
                name: "Greyscale",
            background: BACKGROUND,
            surface: SURFACE,
                barColors: ["#2C3240", "#4B505D", "#6A6E79", "#898D96", "#A7ABB2", "#C6C9CF", "#E5E7EB"]
            });
        }

        revert InvalidPalette(paletteIndex, "Invalid palette index");
    }

    /// @notice Returns the conversion rules for a target palette
    function getPaletteConversion(uint8 targetPalette) internal pure returns (PaletteConversion memory) {
        if (targetPalette == CHROMATIC) {
            return PaletteConversion(ALL_BASE_PALETTES, CHROMATIC, 4);
        }
        if (targetPalette == PASTEL) {
            return PaletteConversion(CHROMATIC, PASTEL, 3);
        }
        if (targetPalette == GREYSCALE) {
            return PaletteConversion(PASTEL, GREYSCALE, 2);
        }

        revert InvalidPalette(targetPalette, "Cannot convert to this palette");
    }
}