// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { Palettes } from "./Palettes.sol";

/// @title SVG Generator Library
/// @notice Generates SVG images for visualization of data using different color palettes
library SVGGenerator {
    using Strings for uint256;

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