// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Palettes Library
/// @notice Defines color palettes for SVG generation
library Palettes {
    /// @notice Structure to hold color information for the SVG
    struct ColorPalette {
        string name;         // Name of the palette
        string background;   // Background color of the entire SVG
        string surface;      // Color of the main surface/container
        string[7] barColors; // Array of colors for the bars
    }

    // Default colors for background and surface
    string constant BACKGROUND = "#000000"; // Black
    string constant SURFACE = "#0e0e0e";    // Dark grey

    /// @notice Returns a color palette based on the provided index
    /// @param paletteIndex Index of the desired color palette (0-6)
    /// @return ColorPalette The selected color scheme
    function getColorPalette(uint8 paletteIndex) internal pure returns (ColorPalette memory) {
        if (paletteIndex == 0) {
            return ColorPalette({
                name: "Classic",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#ff7700", "#ffb200", "#fff000", "#BFF300", "#80F700", "#40FB00", "#00ff00"]
            });
        }
        if (paletteIndex == 1) {
            return ColorPalette({
                name: "Ice",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#5000FB", "#2849FD", "#0092FF", "#00AEFF", "#00C9FF", "#00E4FF", "#00FFFF"]
            });
        }
        if (paletteIndex == 2) {
            return ColorPalette({
                name: "Fire",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF1D00", "#FF5700", "#FF7200", "#FF8D00", "#FFA700", "#FFC200", "#FFDD00"]
            });
        }
        if (paletteIndex == 3) {
            return ColorPalette({
                name: "Punch",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#6F00FF", "#9B00FF", "#C600FF", "#F200FF", "#F600AA", "#FB0080", "#FF0056"]
            });
        }
        if (paletteIndex == 4) {
            return ColorPalette({
                name: "Chromatic",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF0000", "#FF6200", "#FFE300", "#00FF00", "#00CFFF", "#6F00FF", "#F200FF"]
            });
        }
        if (paletteIndex == 5) {
            return ColorPalette({
                name: "Pastel",
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF8080", "#FCAD81", "#FFEC7D", "#78FF78", "#7EEAFC", "#AE7BFF", "#F680FF"]
            });
        }
        // Default to Greyscale
        return ColorPalette({
            name: "Greyscale",
            background: BACKGROUND,
            surface: SURFACE,
            barColors: ["#2C3240", "#4B505D", "#6A6E79", "#898D96", "#A7ABB2", "#C6C9CF", "#E5E7EB"]
        });
    }
}
