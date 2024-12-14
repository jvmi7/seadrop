// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";

/// @title SVG Generator Library
/// @notice Generates SVG images for visualization of data using different color palettes
library SVGGenerator {
    using Strings for uint256;

    /// @notice Structure to hold color information for the SVG
    struct ColorPalette {
        string background;    // Background color of the entire SVG
        string surface;       // Color of the main surface/container
        string[7] barColors; // Array of colors for the bars
    }

    // Default colors for background and surface
    string public constant BACKGROUND = "#000000"; // Black
    string public constant SURFACE = "#0e0e0e";    // Dark grey

    /// @notice Returns a color palette based on the provided index
    /// @param paletteIndex Index of the desired color palette (0-6)
    /// @return ColorPalette The selected color scheme
    function getColorPalette(uint8 paletteIndex) internal pure returns (ColorPalette memory) {
        // PALETTE 0: CLASSIC - Orange to Green gradient
        if (paletteIndex == 0) {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#ff7700", "#ffb200", "#fff000", "#BFF300", "#80F700", "#40FB00", "#00ff00"]
            });
        } 
        // PALETTE 1: ICE - Blue gradient
        else if (paletteIndex == 1) {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#5000FB", "#2849FD", "#0092FF", "#00AEFF", "#00C9FF", "#00E4FF", "#00FFFF"]
            });
        } 
        // PALETTE 2: FIRE - Red to Yellow gradient
        else if (paletteIndex == 2) {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF1D00", "#FF5700", "#FF7200", "#FF8D00", "#FFA700", "#FFC200", "#FFDD00"]
            });
        } 
        // PALETTE 3: PUNCH - Purple to Pink gradient
        else if (paletteIndex == 3) {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#6F00FF", "#9B00FF", "#C600FF", "#F200FF", "#F600AA", "#FB0080", "#FF0056"]
            });
        } 
        // PALETTE 4: CHROMATIC - Rainbow colors
        else if (paletteIndex == 4) {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF0000", "#FF6200", "#FFE300", "#00FF00", "#00CFFF", "#6F00FF", "#F200FF"]
            });
        } 
        // PALETTE 5: PASTEL - Soft pastel colors
        else if (paletteIndex == 5) {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF8080", "#FCAD81", "#FFEC7D", "#78FF78", "#7EEAFC", "#AE7BFF", "#F680FF"]
            });
        } 
        // PALETTE 6: GREYSCALE - Default fallback palette
        else {
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#2C3240", "#4B505D", "#6A6E79", "#898D96", "#A7ABB2", "#C6C9CF", "#E5E7EB"]
            });
        }
    }

    /// @notice Generates an SVG visualization based on provided values and color palette
    /// @param values Array of 7 values to visualize as bars
    /// @param paletteIndex Index of the color palette to use
    /// @return Base64 encoded SVG string
    function generateSVG(uint8[7] memory values, uint8 paletteIndex) internal pure returns (string memory) {
        ColorPalette memory palette = getColorPalette(paletteIndex);
        
        // Initialize SVG with background and surface container
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200">',
            '<rect x="0" y="0" width="1200" height="1200" fill="', palette.background, '" />',
            '<rect x="100" y="100" width="1000" height="1000" fill="', palette.surface, '" rx="80" ry="80" />'
        );

        // Generate individual bars
        for (uint256 i = 0; i < 7; i++) {
            uint256 height;
            string memory barColor;
            uint8 value = values[i];
            
            // Handle special case for zero values
            if (value == 0) {
                height = 560; // Maximum height
                barColor = palette.background; // Use background color to "hide" the bar
            } else {
                // Calculate bar height: minimum 90, maximum 560
                height = 90 + ((value * 470) / 100);
                
                // Color selection logic
                // For CHROMATIC, PASTEL, and GREYSCALE: use sequential colors
                // For others: color based on value ranges
                if (paletteIndex == 4 || paletteIndex == 5 || paletteIndex == 6) {
                    barColor = palette.barColors[i];
                } else {
                    // Select color based on value ranges
                    if (value <= 14) barColor = palette.barColors[0];
                    else if (value <= 28) barColor = palette.barColors[1];
                    else if (value <= 42) barColor = palette.barColors[2];
                    else if (value <= 56) barColor = palette.barColors[3];
                    else if (value <= 70) barColor = palette.barColors[4];
                    else if (value <= 84) barColor = palette.barColors[5];
                    else barColor = palette.barColors[6];
                }
            }

            // Calculate vertical position of bar
            uint256 y = 320 + (560 - height);

            // Add bar to SVG
            svg = abi.encodePacked(
                svg,
                '<rect x="',
                Strings.toString(237 + (i * 106)), // Horizontal position with spacing
                '" y="',
                Strings.toString(y),
                '" width="90" height="',
                Strings.toString(height),
                '" fill="',
                barColor,
                '" rx="45" ry="45" />' // Rounded corners
            );
        }

        // Close SVG tag and encode to Base64
        svg = abi.encodePacked(svg, '</svg>');
        return Base64.encode(svg);
    }
}