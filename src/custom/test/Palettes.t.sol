// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/Palettes.sol";
import "../libraries/Constants.sol";
import "./StringAssertions.sol";

contract PalettesTest is Test, StringAssertions {
    function setUp() public {}

    function testClassicPalette() public {
        Palettes.ColorPalette memory palette = Palettes.getColorPalette(Constants.REDS);
        
        assertEq(palette.name, "classic");
        assertEq(palette.background, "#000000");
        assertEq(palette.surface, "#0e0e0e");
        assertEq(palette.barColors[0], "#ff7700");
        assertEq(palette.barColors[6], "#00ff00");
    }

    function testInvalidPalette() public {
        // Test with an invalid palette index (8)
        vm.expectRevert(abi.encodeWithSelector(Palettes.InvalidPalette.selector, 8, "Invalid palette index"));
        Palettes.getColorPalette(8);
    }

    function testPaletteConversions() public {
        // Test Chromatic conversion
        Palettes.PaletteConversion memory chromatic = Palettes.getPaletteConversion(Constants.CHROMATIC);
        assertEq(chromatic.requiredPalette, type(uint8).max); // ALL_BASE_PALETTES
        assertEq(chromatic.resultPalette, Constants.CHROMATIC);
        assertEq(chromatic.requiredTokenCount, 4);

        // Test Pastel conversion
        Palettes.PaletteConversion memory pastel = Palettes.getPaletteConversion(Constants.PASTEL);
        assertEq(pastel.requiredPalette, Constants.CHROMATIC);
        assertEq(pastel.resultPalette, Constants.PASTEL);
        assertEq(pastel.requiredTokenCount, 3);

        // Test Greyscale conversion
        Palettes.PaletteConversion memory greyscale = Palettes.getPaletteConversion(Constants.GREYSCALE);
        assertEq(greyscale.requiredPalette, Constants.PASTEL);
        assertEq(greyscale.resultPalette, Constants.GREYSCALE);
        assertEq(greyscale.requiredTokenCount, 2);
    }

    function testInvalidPaletteConversion() public {
        // Test conversion for an invalid palette (Classic - which has no conversion rule)
        vm.expectRevert(abi.encodeWithSelector(Palettes.InvalidPalette.selector, Constants.REDS, "Cannot convert to this palette"));
        Palettes.getPaletteConversion(Constants.REDS);
    }

    function testAllPalettesHaveSevenColors() public {
        uint8[8] memory paletteIndices = [
            Constants.REDS,
            Constants.YELLOWS,
            Constants.GREENS,
            Constants.BLUES,
            Constants.VIOLETS,
            Constants.CHROMATIC,
            Constants.PASTEL,
            Constants.GREYSCALE
        ];

        for (uint8 i = 0; i < paletteIndices.length; i++) {
            Palettes.ColorPalette memory palette = Palettes.getColorPalette(paletteIndices[i]);
            for (uint8 j = 0; j < 7; j++) {
                assertTrue(bytes(palette.barColors[j]).length > 0, "Color should not be empty");
                assertTrue(bytes(palette.barColors[j])[0] == "#", "Color should start with #");
            }
        }
    }
}