// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { Palettes } from "./Palettes.sol";

/// @title SVG Generator Library
/// @notice Generates SVG images for visualization of data using different color palettes
library SVGGenerator {
    using Strings for uint256;

    /// @notice Determines color indices for values based on palette type
    /// @param values Array of values to get colors for
    /// @param paletteIndex Index of the color palette being used
    /// @return Array of color indices corresponding to palette.barColors
    function getColorIndices(uint8[7] memory values, uint8 paletteIndex) internal pure returns (uint8[7] memory) {
        uint8[7] memory colorIndices;
        
        // For CHROMATIC, PASTEL, and GREYSCALE: use sequential colors
        if (Palettes.isSpecialPalette(paletteIndex)) {
            for (uint256 i = 0; i < 7; i++) {
                colorIndices[i] = uint8(i);
            }
        } else {
            // For other palettes: determine color based on value ranges
            for (uint256 i = 0; i < 7; i++) {
                uint8 value = values[i];
                if (value <= 14) colorIndices[i] = 0;
                else if (value <= 28) colorIndices[i] = 1;
                else if (value <= 42) colorIndices[i] = 2;
                else if (value <= 56) colorIndices[i] = 3;
                else if (value <= 70) colorIndices[i] = 4;
                else if (value <= 84) colorIndices[i] = 5;
                else colorIndices[i] = 6;
            }
        }
        
        return colorIndices;
    }

    /// @notice Generates an SVG visualization based on provided values and color palette
    /// @param values Array of 7 values to visualize as bars
    /// @param paletteIndex Index of the color palette to use
    /// @return Base64 encoded SVG string
    function generateSVG(uint8[7] memory values, uint8 paletteIndex) internal pure returns (string memory) {
        Palettes.ColorPalette memory palette = Palettes.getColorPalette(paletteIndex);
        
        // Initialize SVG with background and surface container
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200">',
            '<rect x="0" y="0" width="1200" height="1200" fill="', palette.background, '" />',
            '<rect x="100" y="100" width="1000" height="1000" fill="', palette.surface, '" rx="80" ry="80" />'
        );

        // Get color indices for all values
        uint8[7] memory colorIndices = getColorIndices(values, paletteIndex);

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
                barColor = palette.barColors[colorIndices[i]];
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