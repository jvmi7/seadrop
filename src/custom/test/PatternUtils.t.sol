// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/PatternUtils.sol";

contract PatternUtilsTest is Test {
    function setUp() public {}

    function test_UpOnly() public {
        // Up only pattern
        uint8[7] memory values = [1, 2, 3, 3, 5, 6, 7];
        assertEq(PatternUtils.getPattern(values), "up only");
        assertTrue(PatternUtils.isUpOnly(values));

        // Pattern with stagnant values
        uint8[7] memory values2 = [1, 1, 1, 3, 5, 6, 7];
        assertEq(PatternUtils.getPattern(values2), "up only");
        assertTrue(PatternUtils.isUpOnly(values2));

        // Non increasing pattern
        uint8[7] memory values3 = [1, 1, 1, 1, 1, 1, 1];
        assertEq(PatternUtils.getPattern(values3), "none");
        assertFalse(PatternUtils.isUpOnly(values3));
    }

    function test_DownOnly() public {
        // Down only pattern
        uint8[7] memory values = [7, 6, 5, 4, 3, 2, 1];
        assertEq(PatternUtils.getPattern(values), "down only");
        assertTrue(PatternUtils.isDownOnly(values));

        // Pattern with stagnant values
        uint8[7] memory values2 = [7, 7, 7, 3, 1, 1, 1];
        assertEq(PatternUtils.getPattern(values2), "down only");
        assertTrue(PatternUtils.isDownOnly(values2));

        // Non decreasing pattern
        uint8[7] memory values3 = [1, 1, 1, 1, 1, 1, 1];
        assertEq(PatternUtils.getPattern(values3), "none");
        assertFalse(PatternUtils.isDownOnly(values3));
    }

    function test_Peak() public {
        // Peak pattern
        uint8[7] memory values = [1, 2, 3, 4, 3, 2, 1];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "peak");
        assertTrue(PatternUtils.isPeak(values, reversals));

        // Peak pattern with stagnant values before peak
        uint8[7] memory values2 = [1, 1, 1, 4, 3, 2, 1];
        uint8 reversals2 = PatternUtils.countReversals(values2);
        assertEq(PatternUtils.getPattern(values2), "peak");
        assertTrue(PatternUtils.isPeak(values2, reversals2));

        // Peak pattern with stagnant values after peak
        uint8[7] memory values3 = [1, 2, 3, 4, 4, 1, 1];
        uint8 reversals3 = PatternUtils.countReversals(values3);
        assertEq(PatternUtils.getPattern(values3), "peak");
        assertTrue(PatternUtils.isPeak(values3, reversals3));

        // Peak pattern with stagnant peak
        uint8[7] memory values4 = [1, 1, 1, 4, 4, 4, 1];
        uint8 reversals4 = PatternUtils.countReversals(values4);
        assertEq(PatternUtils.getPattern(values4), "peak");
        assertTrue(PatternUtils.isPeak(values4, reversals4));
    }

    function test_Valley() public { 
        // Valley pattern
        uint8[7] memory values = [4, 3, 2, 1, 2, 3, 4];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "valley");
        assertTrue(PatternUtils.isValley(values, reversals));

        // Valley pattern with stagnant values before valley
        uint8[7] memory values2 = [4, 3, 2, 1, 1, 1, 4];
        uint8 reversals2 = PatternUtils.countReversals(values2);
        assertEq(PatternUtils.getPattern(values2), "valley");
        assertTrue(PatternUtils.isValley(values2, reversals2));

        // Valley pattern with stagnant values after valley
        uint8[7] memory values3 = [4, 3, 2, 1, 2, 3, 4];
        uint8 reversals3 = PatternUtils.countReversals(values3);
        assertEq(PatternUtils.getPattern(values3), "valley");
        assertTrue(PatternUtils.isValley(values3, reversals3));

        // Valley pattern with stagnant valley
        uint8[7] memory values4 = [4, 3, 2, 1, 1, 1, 4];
        uint8 reversals4 = PatternUtils.countReversals(values4);
        assertEq(PatternUtils.getPattern(values4), "valley");
        assertTrue(PatternUtils.isValley(values4, reversals4));
    }

    function test_UpDownUp() public {
        // Base UpDownUp pattern
        
        uint8[7] memory values = [1, 2, 3, 2, 1, 2, 3];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values, reversals));

        // Stagnant values in first upward trend
        uint8[7] memory values2 = [1, 1, 3, 2, 1, 2, 3];
        uint8 reversals2 = PatternUtils.countReversals(values2);
        assertEq(PatternUtils.getPattern(values2), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values2, reversals2));

        // Stagnant values at first peak
        uint8[7] memory values3 = [1, 2, 3, 3, 1, 2, 3];
        uint8 reversals3 = PatternUtils.countReversals(values3);
        assertEq(PatternUtils.getPattern(values3), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values3, reversals3));

        // Stagnant values during downward trend
        uint8[7] memory values4 = [1, 2, 3, 2, 2, 2, 3];
        uint8 reversals4 = PatternUtils.countReversals(values4);
        assertEq(PatternUtils.getPattern(values4), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values4, reversals4));

        // Stagnant values at valley
        uint8[7] memory values5 = [1, 2, 3, 2, 1, 1, 3];
        uint8 reversals5 = PatternUtils.countReversals(values5);
        assertEq(PatternUtils.getPattern(values5), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values5, reversals5));

        // Stagnant values in final upward trend
        uint8[7] memory values6 = [1, 2, 3, 2, 1, 2, 2];
        uint8 reversals6 = PatternUtils.countReversals(values6);
        assertEq(PatternUtils.getPattern(values6), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values6, reversals6));

        // Multiple stagnant regions
        uint8[7] memory values7 = [1, 1, 3, 2, 1, 1, 2];
        uint8 reversals7 = PatternUtils.countReversals(values7);
        assertEq(PatternUtils.getPattern(values7), "\u2191\u2193\u2191");
        assertTrue(PatternUtils.isUpDownUp(values7, reversals7));
    }

    function test_DownUpDown() public {
        // Base DownUpDown pattern
        uint8[7] memory values = [3, 2, 1, 2, 3, 2, 1];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values, reversals));

        // Stagnant values in first downward trend
        uint8[7] memory values2 = [3, 3, 1, 2, 3, 2, 1];
        uint8 reversals2 = PatternUtils.countReversals(values2);
        assertEq(PatternUtils.getPattern(values2), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values2, reversals2));

        // Stagnant values at first valley
        uint8[7] memory values3 = [3, 2, 1, 1, 3, 2, 1];
        uint8 reversals3 = PatternUtils.countReversals(values3);
        assertEq(PatternUtils.getPattern(values3), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values3, reversals3));

        // Stagnant values during upward trend
        uint8[7] memory values4 = [3, 2, 1, 2, 2, 2, 1];
        uint8 reversals4 = PatternUtils.countReversals(values4);
        assertEq(PatternUtils.getPattern(values4), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values4, reversals4));

        // Stagnant values at peak
        uint8[7] memory values5 = [3, 2, 1, 2, 3, 3, 1];
        uint8 reversals5 = PatternUtils.countReversals(values5);
        assertEq(PatternUtils.getPattern(values5), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values5, reversals5));

        // Stagnant values in final downward trend
        uint8[7] memory values6 = [3, 2, 1, 2, 3, 1, 1];
        uint8 reversals6 = PatternUtils.countReversals(values6);
        assertEq(PatternUtils.getPattern(values6), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values6, reversals6));

        // Multiple stagnant regions
        uint8[7] memory values7 = [3, 3, 1, 2, 3, 1, 1];
        uint8 reversals7 = PatternUtils.countReversals(values7);
        assertEq(PatternUtils.getPattern(values7), "\u2193\u2191\u2193");
        assertTrue(PatternUtils.isDownUpDown(values7, reversals7));
    }

    function test_WShape() public {
        // Base W shape pattern
        uint8[7] memory values = [5, 4, 3, 4, 3, 4, 5];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "\u2193\u2191\u2193\u2191", "Base W shape pattern failed");
        assertTrue(PatternUtils.isWShape(values, reversals), "Base W shape pattern check failed");

        // Stagnant values in first downward trend
        uint8[7] memory values2 = [5, 5, 3, 4, 3, 4, 5];
        uint8 reversals2 = PatternUtils.countReversals(values2);
        // assertEq(reversals2, 3);
        assertEq(PatternUtils.getPattern(values2), "\u2193\u2191\u2193\u2191", "Stagnant values in first downward trend failed");
        assertTrue(PatternUtils.isWShape(values2, reversals2), "Stagnant values in first downward trend check failed");

        // // Stagnant values at first valley
        uint8[7] memory values3 = [5, 4, 3, 3, 4, 3, 5];
        uint8 reversals3 = PatternUtils.countReversals(values3);
        assertEq(PatternUtils.getPattern(values3), "\u2193\u2191\u2193\u2191", "Stagnant values at first valley failed");
        assertTrue(PatternUtils.isWShape(values3, reversals3), "Stagnant values at first valley check failed");

        // // Stagnant values in first upward trend
        uint8[7] memory values4 = [5, 4, 3, 4, 4, 3, 5];
        uint8 reversals4 = PatternUtils.countReversals(values4);
        assertEq(PatternUtils.getPattern(values4), "\u2193\u2191\u2193\u2191", "Stagnant values in first upward trend failed");
        assertTrue(PatternUtils.isWShape(values4, reversals4), "Stagnant values in first upward trend check failed");

        // Stagnant values at middle peak
        uint8[7] memory values5 = [5, 4, 3, 4, 3, 4, 4];
        uint8 reversals5 = PatternUtils.countReversals(values5);
        assertEq(PatternUtils.getPattern(values5), "\u2193\u2191\u2193\u2191", "Stagnant values at middle peak failed");
        assertTrue(PatternUtils.isWShape(values5, reversals5), "Stagnant values at middle peak check failed");

        // Stagnant values in second downward trend
        uint8[7] memory values6 = [5, 4, 3, 4, 3, 3, 5];
        uint8 reversals6 = PatternUtils.countReversals(values6);
        assertEq(PatternUtils.getPattern(values6), "\u2193\u2191\u2193\u2191", "Stagnant values in second downward trend failed");
        assertTrue(PatternUtils.isWShape(values6, reversals6), "Stagnant values in second downward trend check failed");

        // Stagnant values at second valley
        uint8[7] memory values7 = [5, 4, 3, 4, 3, 3, 5];
        uint8 reversals7 = PatternUtils.countReversals(values7);
        assertEq(PatternUtils.getPattern(values7), "\u2193\u2191\u2193\u2191", "Stagnant values at second valley failed");
        assertTrue(PatternUtils.isWShape(values7, reversals7), "Stagnant values at second valley check failed");

        // Stagnant values in final upward trend
        uint8[7] memory values8 = [5, 4, 3, 4, 3, 4, 4];
        uint8 reversals8 = PatternUtils.countReversals(values8);
        assertEq(PatternUtils.getPattern(values8), "\u2193\u2191\u2193\u2191", "Stagnant values in final upward trend failed");
        assertTrue(PatternUtils.isWShape(values8, reversals8), "Stagnant values in final upward trend check failed");

        // Multiple stagnant regions
        uint8[7] memory values9 = [5, 5, 3, 4, 3, 3, 5];
        uint8 reversals9 = PatternUtils.countReversals(values9);
        assertEq(PatternUtils.getPattern(values9), "\u2193\u2191\u2193\u2191", "Multiple stagnant regions failed");
        assertTrue(PatternUtils.isWShape(values9, reversals9), "Multiple stagnant regions check failed");
    }

    function test_MShape() public {
        // Base M shape pattern
        uint8[7] memory values = [1, 2, 3, 2, 3, 2, 1];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "\u2191\u2193\u2191\u2193", "Base M shape pattern failed");
        assertTrue(PatternUtils.isMShape(values, reversals), "Base M shape pattern check failed");

        // Stagnant values in first upward trend
        uint8[7] memory values2 = [1, 1, 3, 2, 3, 2, 1];
        uint8 reversals2 = PatternUtils.countReversals(values2);
        assertEq(PatternUtils.getPattern(values2), "\u2191\u2193\u2191\u2193", "Stagnant values in first upward trend failed");
        assertTrue(PatternUtils.isMShape(values2, reversals2), "Stagnant values in first upward trend check failed");

        // Stagnant values at first peak
        uint8[7] memory values3 = [1, 2, 3, 3, 2, 3, 1];
        uint8 reversals3 = PatternUtils.countReversals(values3);
        assertEq(PatternUtils.getPattern(values3), "\u2191\u2193\u2191\u2193", "Stagnant values at first peak failed");
        assertTrue(PatternUtils.isMShape(values3, reversals3), "Stagnant values at first peak check failed");

        // Stagnant values in first downward trend
        uint8[7] memory values4 = [1, 2, 3, 2, 2, 3, 1];
        uint8 reversals4 = PatternUtils.countReversals(values4);
        assertEq(PatternUtils.getPattern(values4), "\u2191\u2193\u2191\u2193", "Stagnant values in first downward trend failed");
        assertTrue(PatternUtils.isMShape(values4, reversals4), "Stagnant values in first downward trend check failed");

        // Stagnant values at middle valley
        uint8[7] memory values5 = [1, 2, 3, 2, 3, 3, 1];
        uint8 reversals5 = PatternUtils.countReversals(values5);
        assertEq(PatternUtils.getPattern(values5), "\u2191\u2193\u2191\u2193", "Stagnant values at middle valley failed");
        assertTrue(PatternUtils.isMShape(values5, reversals5), "Stagnant values at middle valley check failed");

        // Stagnant values in second upward trend
        uint8[7] memory values6 = [1, 2, 3, 2, 3, 2, 2];
        uint8 reversals6 = PatternUtils.countReversals(values6);
        assertEq(PatternUtils.getPattern(values6), "\u2191\u2193\u2191\u2193", "Stagnant values in second upward trend failed");
        assertTrue(PatternUtils.isMShape(values6, reversals6), "Stagnant values in second upward trend check failed");

        // Stagnant values at second peak
        uint8[7] memory values7 = [1, 2, 3, 2, 3, 2, 1];
        uint8 reversals7 = PatternUtils.countReversals(values7);
        assertEq(PatternUtils.getPattern(values7), "\u2191\u2193\u2191\u2193", "Stagnant values at second peak failed");
        assertTrue(PatternUtils.isMShape(values7, reversals7), "Stagnant values at second peak check failed");

        // Stagnant values in final downward trend
        uint8[7] memory values8 = [1, 2, 3, 2, 3, 2, 1];
        uint8 reversals8 = PatternUtils.countReversals(values8);
        assertEq(PatternUtils.getPattern(values8), "\u2191\u2193\u2191\u2193", "Stagnant values in final downward trend failed");
        assertTrue(PatternUtils.isMShape(values8, reversals8), "Stagnant values in final downward trend check failed");

        // Multiple stagnant regions
        uint8[7] memory values9 = [1, 1, 3, 2, 3, 2, 1];
        uint8 reversals9 = PatternUtils.countReversals(values9);
        assertEq(PatternUtils.getPattern(values9), "\u2191\u2193\u2191\u2193", "Multiple stagnant regions failed");
        assertTrue(PatternUtils.isMShape(values9, reversals9), "Multiple stagnant regions check failed");
    }

    function test_Oscillating() public {
        uint8[7] memory values = [1, 2, 1, 2, 1, 2, 1];
        uint8 reversals = PatternUtils.countReversals(values);
        assertEq(PatternUtils.getPattern(values), "oscillating");
        assertTrue(PatternUtils.isOscillating(reversals));
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