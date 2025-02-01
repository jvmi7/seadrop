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
    string constant SURFACE = "#111111";

    /// @notice Palette indices for different color schemes
    uint8 constant REDS = Constants.REDS;
    uint8 constant YELLOWS = Constants.YELLOWS;
    uint8 constant GREENS = Constants.GREENS;
    uint8 constant BLUES = Constants.BLUES;
    uint8 constant VIOLETS = Constants.VIOLETS;
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
        if (paletteIndex == REDS) {
            return ColorPalette({
                name: "reds",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ['#e900d1', '#ff00b7', '#ff007a', '#ff003c', '#ff071e', '#ff180d', '#ff3f14']
            });
        }
        if (paletteIndex == YELLOWS) {
            return ColorPalette({
                name: "yellows",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ['#FF6200', '#FF7700', '#FF8C00', '#FFA100', '#FFB700', '#FFCC00', '#FFE100']
            });
        }
        if (paletteIndex == GREENS) {
            return ColorPalette({
                name: "greens",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ['#00cc8e', '#00de79', '#00f057', '#14ff00', '#6fff00', '#9bff00', '#bdff00']
            });
        }
        if (paletteIndex == BLUES) {
            return ColorPalette({
                name: "blues",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ['#0057ff', '#0071ff', '#008aff', '#00a4ff', '#00bdff', '#00d7ff', '#00f0ff']
            });
        }
        if (paletteIndex == VIOLETS) {
            return ColorPalette({
                name: "violets",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ['#6100ff', '#770fff', '#8b1fff', '#9d2eff', '#ae3dff', '#bd4dff', '#cb5cff']
            });
        }
        if (paletteIndex == CHROMATIC) {
            return ColorPalette({
                name: "chromatic",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF0000", "#FF6200", "#FFE300", "#00FF00", "#00CFFF", "#6F00FF", "#F200FF"]
            });
        }
        if (paletteIndex == PASTEL) {
            return ColorPalette({
                name: "pastel",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF8080", "#FCAD81", "#FFEC7D", "#78FF78", "#7EEAFC", "#AE7BFF", "#F680FF"]
            });
        } if (paletteIndex == GREYSCALE) {  
            return ColorPalette({
                name: "greyscale",
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

    function isSpecialPalette(uint8 paletteIndex) internal pure returns (bool) {
        return paletteIndex != REDS && paletteIndex != YELLOWS && paletteIndex != GREENS && paletteIndex != BLUES && paletteIndex != VIOLETS;
    }
}
