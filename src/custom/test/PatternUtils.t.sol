// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/PatternUtils.sol";

contract PatternUtilsTest is Test {
    function setUp() public {}

    function test_UpOnly() public {
        uint8[7] memory values = [1, 2, 3, 4, 5, 6, 7];
        assertEq(PatternUtils.getPattern(values), "up only");
        assertTrue(PatternUtils.isUpOnly(values));
    }

    function test_DownOnly() public {
        uint8[7] memory values = [7, 6, 5, 4, 3, 2, 1];
        assertEq(PatternUtils.getPattern(values), "down only");
        assertTrue(PatternUtils.isDownOnly(values));
    }

    function test_Peak() public {
        uint8[7] memory values = [1, 2, 3, 4, 3, 2, 1];
        assertEq(PatternUtils.getPattern(values), "peak");
        assertTrue(PatternUtils.isPeak(values));
    }

    function test_Valley() public {
        uint8[7] memory values = [4, 3, 2, 1, 2, 3, 4];
        assertEq(PatternUtils.getPattern(values), "valley");
        assertTrue(PatternUtils.isValley(values));
    }

    function test_UpDownUp() public {
        uint8[7] memory values = [1, 2, 3, 2, 1, 2, 3];
        assertEq(PatternUtils.getPattern(values), "up down up");
        assertTrue(PatternUtils.isUpDownUp(values));
    }

    function test_DownUpDown() public {
        uint8[7] memory values = [3, 2, 1, 2, 3, 2, 1];
        assertEq(PatternUtils.getPattern(values), "down up down");
        assertTrue(PatternUtils.isDownUpDown(values));
    }

    function test_WShape() public {
        uint8[7] memory values = [5, 4, 3, 4, 3, 4, 5];
        assertEq(PatternUtils.getPattern(values), "w shape");
        assertTrue(PatternUtils.isWShape(values));
    }

    function test_MShape() public {
        uint8[7] memory values = [1, 2, 3, 2, 3, 2, 1];
        assertEq(PatternUtils.getPattern(values), "m shape");
        assertTrue(PatternUtils.isMShape(values));
    }

    function test_Oscillating() public {
        uint8[7] memory values = [1, 2, 1, 2, 1, 2, 1];
        assertEq(PatternUtils.getPattern(values), "oscillating");
        assertTrue(PatternUtils.isOscillating(values));
    }

    function test_NoPattern() public {
        // A random sequence that doesn't match any pattern
        uint8[7] memory values = [3, 4, 2, 5, 1, 3, 4];
        assertEq(PatternUtils.getPattern(values), "none");
    }

    function test_CountReversals() public {
        uint8[7] memory values = [1, 2, 1, 2, 1, 2, 1]; // Oscillating pattern
        assertEq(PatternUtils.countReversals(values), 5);
        
        values = [1, 2, 3, 2, 1, 2, 3]; // Up-Down-Up pattern
        assertEq(PatternUtils.countReversals(values), 2);
        
        values = [1, 2, 3, 4, 5, 6, 7]; // Up only pattern
        assertEq(PatternUtils.countReversals(values), 0);
    }
}