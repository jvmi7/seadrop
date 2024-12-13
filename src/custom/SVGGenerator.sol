// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";

library SVGGenerator {
    using Strings for uint256;

    struct ColorPalette {
        string background;
        string surface;
        string[7] barColors;
    }

    string public constant BACKGROUND = "#000000";
    string public constant SURFACE = "#0e0e0e";

    function getColorPalette(uint8 paletteIndex) internal pure returns (ColorPalette memory) {
        if (paletteIndex == 0) { // CLASSIC
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#ff7700", "#ffb200", "#fff000", "#BFF300", "#80F700", "#40FB00", "#00ff00"]
            });
        } else if (paletteIndex == 1) { // ICE
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#5000FB", "#2849FD", "#0092FF", "#00AEFF", "#00C9FF", "#00E4FF", "#00FFFF"]
            });
        } else if (paletteIndex == 2) { // FIRE
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF1D00", "#FF5700", "#FF7200", "#FF8D00", "#FFA700", "#FFC200", "#FFDD00"]
            });
        } else if (paletteIndex == 3) { // PUNCH
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#6F00FF", "#9B00FF", "#C600FF", "#F200FF", "#F600AA", "#FB0080", "#FF0056"]
            });
        } else if (paletteIndex == 4) { // CHROMATIC
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF0000", "#FF6200", "#FFE300", "#00FF00", "#00CFFF", "#6F00FF", "#F200FF"]
            });
        } else if (paletteIndex == 5) { // PASTEL
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#FF8080", "#FCAD81", "#FFEC7D", "#78FF78", "#7EEAFC", "#AE7BFF", "#F680FF"]
            });
        } else { // GREYSCALE
            return ColorPalette({
                background: BACKGROUND,
                surface: SURFACE,
                barColors: ["#2C3240", "#4B505D", "#6A6E79", "#898D96", "#A7ABB2", "#C6C9CF", "#E5E7EB"]
            });
        }
    }

    function generateSVG(uint8[7] memory values, uint8 paletteIndex) internal pure returns (string memory) {
        ColorPalette memory palette = getColorPalette(paletteIndex);
        
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200">',
            '<rect x="0" y="0" width="1200" height="1200" fill="', palette.background, '" />',
            '<rect x="100" y="100" width="1000" height="1000" fill="', palette.surface, '" rx="80" ry="80" />'
        );

        // Generate bars with dynamic heights based on values
        for (uint256 i = 0; i < 7; i++) {
            uint256 height;
            string memory barColor;
            uint8 value = values[i];
            
            if (value == 0) {
                height = 560; // Max height for zero values
                barColor = palette.background; // Use background color for zero values
            } else {
                height = 90 + ((value * 470) / 100); // Min height 90, max height 560
                
                // Use sequential colors for specific palettes, value-based for others
                if (paletteIndex == 4 || paletteIndex == 5 || paletteIndex == 6) {
                    barColor = palette.barColors[i];
                } else {
                    if (value <= 14) barColor = palette.barColors[0];
                    else if (value <= 28) barColor = palette.barColors[1];
                    else if (value <= 42) barColor = palette.barColors[2];
                    else if (value <= 56) barColor = palette.barColors[3];
                    else if (value <= 70) barColor = palette.barColors[4];
                    else if (value <= 84) barColor = palette.barColors[5];
                    else barColor = palette.barColors[6];
                }
            }

            uint256 y = 320 + (560 - height); // Adjust y position based on height

            svg = abi.encodePacked(
                svg,
                '<rect x="',
                Strings.toString(237 + (i * 106)),
                '" y="',
                Strings.toString(y),
                '" width="90" height="',
                Strings.toString(height),
                '" fill="',
                barColor,
                '" rx="45" ry="45" />'
            );
        }

        svg = abi.encodePacked(svg, '</svg>');
        
        return Base64.encode(svg);
    }
}