// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/BadgeUtils.sol";

contract BadgeUtilsTest is Test {
    function testHighRoller() public {
        uint8[7] memory validCase = [80, 76, 85, 90, 88, 95, 82];
        uint8[7] memory invalidCase = [80, 76, 85, 50, 88, 95, 82];
        uint8[7] memory allHundred = [100, 100, 100, 100, 100, 100, 100];
        uint8[7] memory allZero = [0, 0, 0, 0, 0, 0, 0];

        assertTrue(BadgeUtils.isHighRoller(validCase));
        assertFalse(BadgeUtils.isHighRoller(invalidCase));
        assertTrue(BadgeUtils.isHighRoller(allHundred));
        assertFalse(BadgeUtils.isHighRoller(allZero));
    }

    function testLowStakes() public {
        uint8[7] memory validCase = [15, 20, 10, 5, 15, 20, 10];
        uint8[7] memory invalidHighCase = [15, 50, 10, 5, 15, 20, 10];
        uint8[7] memory invalidZeroCase = [15, 0, 10, 5, 15, 20, 10];
        uint8[7] memory allOne = [1, 1, 1, 1, 1, 1, 1];

        assertTrue(BadgeUtils.isLowStakes(validCase));
        assertFalse(BadgeUtils.isLowStakes(invalidHighCase));
        assertFalse(BadgeUtils.isLowStakes(invalidZeroCase));
        assertTrue(BadgeUtils.isLowStakes(allOne));
    }

    function testRugged() public {
        uint8[7] memory validCase = [50, 60, 40, 30, 80, 75, 5];
        uint8[7] memory invalidLastZero = [50, 60, 40, 30, 80, 75, 0];
        uint8[7] memory invalidNotRugged = [50, 60, 40, 30, 80, 74, 5];
        uint8[7] memory invalidTooHigh = [50, 60, 40, 30, 80, 75, 6];

        assertTrue(BadgeUtils.isRugged(validCase));
        assertFalse(BadgeUtils.isRugged(invalidLastZero));
        assertFalse(BadgeUtils.isRugged(invalidNotRugged));
        assertFalse(BadgeUtils.isRugged(invalidTooHigh));
    }

    function testBlackSwan() public {
        uint8[7] memory validCase = [95, 4, 50, 60, 70, 80, 90];
        uint8[7] memory validLateCase = [10, 20, 95, 4, 50, 60, 70];
        uint8[7] memory invalidCase = [95, 10, 50, 60, 70, 80, 90];
        uint8[7] memory invalidZeroCase = [95, 0, 50, 60, 70, 80, 90];

        assertTrue(BadgeUtils.isBlackSwan(validCase));
        assertTrue(BadgeUtils.isBlackSwan(validLateCase));
        assertFalse(BadgeUtils.isBlackSwan(invalidCase));
        assertFalse(BadgeUtils.isBlackSwan(invalidZeroCase));
    }

    function testMoon() public {
        uint8[7] memory validCase = [5, 96, 50, 60, 70, 80, 90];
        uint8[7] memory validLateCase = [10, 20, 30, 40, 5, 96, 90];
        uint8[7] memory invalidCase = [5, 94, 50, 60, 70, 80, 90];
        uint8[7] memory invalidZeroCase = [5, 0, 50, 60, 70, 80, 90];

        assertTrue(BadgeUtils.isMoon(validCase));
        assertTrue(BadgeUtils.isMoon(validLateCase));
        assertFalse(BadgeUtils.isMoon(invalidCase));
        assertFalse(BadgeUtils.isMoon(invalidZeroCase));
    }

    function testComeback() public {
        uint8[7] memory validCase = [5, 20, 30, 40, 50, 60, 80];
        uint8[7] memory invalidNoLow = [15, 20, 30, 40, 50, 60, 80];
        uint8[7] memory invalidNotHighEnough = [5, 20, 30, 40, 50, 60, 74];
        uint8[7] memory validEdgeCase = [9, 20, 30, 40, 50, 60, 76];

        assertTrue(BadgeUtils.isComeback(validCase));
        assertFalse(BadgeUtils.isComeback(invalidNoLow));
        assertFalse(BadgeUtils.isComeback(invalidNotHighEnough));
        assertTrue(BadgeUtils.isComeback(validEdgeCase));
    }

    function testRagsToRiches() public {
        uint8[7] memory validCase = [5, 20, 30, 40, 50, 60, 90];
        uint8[7] memory invalidStartTooHigh = [10, 20, 30, 40, 50, 60, 90];
        uint8[7] memory invalidEndTooLow = [5, 20, 30, 40, 50, 60, 89];
        uint8[7] memory validEdgeCase = [9, 20, 30, 40, 50, 60, 90];

        assertTrue(BadgeUtils.isRagsToRiches(validCase));
        assertFalse(BadgeUtils.isRagsToRiches(invalidStartTooHigh));
        assertFalse(BadgeUtils.isRagsToRiches(invalidEndTooLow));
        assertTrue(BadgeUtils.isRagsToRiches(validEdgeCase));
    }

    function testFumbled() public {
        uint8[7] memory validCase = [90, 80, 70, 60, 50, 40, 9];
        uint8[7] memory invalidStartTooLow = [89, 80, 70, 60, 50, 40, 9];
        uint8[7] memory invalidEndTooHigh = [90, 80, 70, 60, 50, 40, 10];
        uint8[7] memory invalidLastZero = [90, 80, 70, 60, 50, 40, 0];

        assertTrue(BadgeUtils.isFumbled(validCase));
        assertFalse(BadgeUtils.isFumbled(invalidStartTooLow));
        assertFalse(BadgeUtils.isFumbled(invalidEndTooHigh));
        assertFalse(BadgeUtils.isFumbled(invalidLastZero));
    }

    // ... existing code ...

function testHighRollerEdgeCases() public {
    // Test exactly 75 for all values (minimum threshold)
    uint8[7] memory allSeventyFive = [76, 76, 76, 76, 76, 76, 76];
    // Test mixed case with exactly 75
    uint8[7] memory mixedWithSeventyFive = [76, 76, 80, 76, 90, 76, 85];
    // Test single value below 75
    uint8[7] memory singleFailure = [100, 100, 50, 100, 100, 100, 100];

    assertTrue(BadgeUtils.isHighRoller(allSeventyFive));
    assertTrue(BadgeUtils.isHighRoller(mixedWithSeventyFive));
    assertFalse(BadgeUtils.isHighRoller(singleFailure));
}

function testLowStakesEdgeCases() public {
    // Test exactly 25 (maximum threshold)
    uint8[7] memory allTwentyFive = [24, 24, 24, 24, 24, 24, 24];
    // Test mixed case with exactly 25
    uint8[7] memory mixedWithTwentyFive = [20, 24, 15, 24, 10, 24, 5];
    // Test single value above 25
    uint8[7] memory singleFailure = [10, 10, 50, 10, 10, 10, 10];

    assertTrue(BadgeUtils.isLowStakes(allTwentyFive));
    assertTrue(BadgeUtils.isLowStakes(mixedWithTwentyFive));
    assertFalse(BadgeUtils.isLowStakes(singleFailure));
}

function testBlackSwanEdgeCases() public {
    // Test minimum drop (91 to 4)
    uint8[7] memory minimumDrop = [91, 1, 50, 60, 70, 80, 90];
    // Test maximum low value (5)
    uint8[7] memory maximumLow = [95, 5, 50, 60, 70, 80, 90];
    // Test pattern at end of array
    uint8[7] memory endPattern = [10, 20, 30, 40, 50, 95, 4];
    // Test invalid minimum drop
    uint8[7] memory invalidMinDrop = [90, 4, 50, 60, 70, 80, 90];

    string memory errorMsg = "Expected minimum drop (91->4) to qualify as BlackSwan but it did not";
    assertEq(BadgeUtils.isBlackSwan(minimumDrop), true, errorMsg);
    errorMsg = "Expected maximum low value (5) to qualify as BlackSwan but it did not";
    assertEq(BadgeUtils.isBlackSwan(maximumLow), true, errorMsg);
    errorMsg = "Expected end pattern to qualify as BlackSwan but it did not";
    assertEq(BadgeUtils.isBlackSwan(endPattern), true, errorMsg);
    errorMsg = "Expected invalid minimum drop to not qualify as BlackSwan but it did";
    assertEq(BadgeUtils.isBlackSwan(invalidMinDrop), false, errorMsg);
}

function testMoonEdgeCases() public {
    // Test minimum rise (5 to 95)
    uint8[7] memory minimumRise = [5, 95, 50, 60, 70, 80, 90];
    // Test maximum initial value (5)
    uint8[7] memory maximumStart = [5, 96, 50, 60, 70, 80, 90];
    // Test pattern at end of array
    uint8[7] memory endPattern = [10, 20, 30, 40, 50, 5, 96];
    // Test invalid minimum rise
    uint8[7] memory invalidMinRise = [5, 94, 50, 60, 70, 80, 90];

    assertTrue(BadgeUtils.isMoon(minimumRise));
    assertTrue(BadgeUtils.isMoon(maximumStart));
    assertTrue(BadgeUtils.isMoon(endPattern));
    assertFalse(BadgeUtils.isMoon(invalidMinRise));
}

function testComebackAndRagsEdgeCases() public {
    // Test exactly 10 start (invalid for both)
    uint8[7] memory exactlyTen = [10, 20, 30, 40, 50, 60, 90];
    // Test exactly 75/90 end thresholds
    uint8[7] memory exactThresholds = [5, 20, 30, 40, 50, 60, 76];
    
    assertFalse(
        BadgeUtils.isComeback(exactlyTen),
        "Starting value of 10 should not qualify for Comeback badge"
    );
    assertFalse(
        BadgeUtils.isRagsToRiches(exactlyTen),
        "Starting value of 10 should not qualify for RagsToRiches badge"
    );
    assertTrue(
        BadgeUtils.isComeback(exactThresholds),
        "Ending value of exactly 76 should qualify for Comeback badge"
    );
    assertFalse(
        BadgeUtils.isRagsToRiches(exactThresholds),
        "Ending value of 76 should not qualify for RagsToRiches badge (requires 90+)"
    );
}

function testFumbledEdgeCases() public {
    // Test exactly 90 start
    uint8[7] memory exactlyNinety = [90, 80, 70, 60, 50, 40, 5];
    // Test exactly 10 end
    uint8[7] memory exactlyTenEnd = [95, 80, 70, 60, 50, 40, 10];
    // Test non-monotonic decrease
    uint8[7] memory nonMonotonic = [95, 80, 85, 60, 50, 40, 5];
    
    assertTrue(BadgeUtils.isFumbled(exactlyNinety));
    assertFalse(BadgeUtils.isFumbled(exactlyTenEnd));
    assertTrue(BadgeUtils.isFumbled(nonMonotonic));
}

    function testSpike() public {
        // Valid spike cases
        uint8[7] memory validMiddleSpike = [20, 20, 90, 20, 20, 20, 20];
        uint8[7] memory validFirstSpike = [90, 20, 20, 20, 20, 20, 20];
        uint8[7] memory validLastSpike = [20, 20, 20, 20, 20, 20, 90];
        uint8[7] memory barelyValidSpike = [10, 10, 61, 10, 10, 10, 10];

        // Invalid cases
        uint8[7] memory invalidNoSpike = [20, 30, 40, 50, 60, 70, 80];
        uint8[7] memory invalidNotEnoughDiff = [20, 20, 69, 20, 20, 20, 20];
        uint8[7] memory invalidWithZero = [20, 0, 90, 20, 20, 20, 20];
        uint8[7] memory invalidAllSame = [50, 50, 50, 50, 50, 50, 50];
        uint8[7] memory invalidTwoHigh = [90, 20, 90, 20, 20, 20, 20];
        uint8[7] memory invalidMaxValues = [100, 100, 100, 100, 100, 100, 100];

        // Test valid cases
        assertTrue(BadgeUtils.isSpike(validMiddleSpike), "Middle spike should be valid");
        assertTrue(BadgeUtils.isSpike(validFirstSpike), "First position spike should be valid");
        assertTrue(BadgeUtils.isSpike(validLastSpike), "Last position spike should be valid");
        assertTrue(BadgeUtils.isSpike(barelyValidSpike), "Barely valid spike (51 point difference) should be valid");

        // Test invalid cases
        assertFalse(BadgeUtils.isSpike(invalidNoSpike), "Gradually increasing values should not be valid");
        assertFalse(BadgeUtils.isSpike(invalidNotEnoughDiff), "49 point difference should not be valid");
        assertFalse(BadgeUtils.isSpike(invalidWithZero), "Array containing zero should not be valid");
        assertFalse(BadgeUtils.isSpike(invalidAllSame), "All same values should not be valid");
        assertFalse(BadgeUtils.isSpike(invalidTwoHigh), "Two high values should not be valid");
        assertFalse(BadgeUtils.isSpike(invalidMaxValues), "All maximum values should not be valid");

        // Edge cases with specific values
        uint8[7] memory edgeCase1 = [1, 1, 52, 1, 1, 1, 1];
        uint8[7] memory edgeCase2 = [100, 49, 49, 49, 49, 49, 49];
        uint8[7] memory edgeCase3 = [49, 49, 49, 49, 49, 49, 100];

        assertTrue(BadgeUtils.isSpike(edgeCase1), "Minimum valid values should work");
        assertTrue(BadgeUtils.isSpike(edgeCase2), "Maximum value spike at start should work");
        assertTrue(BadgeUtils.isSpike(edgeCase3), "Maximum value spike at end should work");
    }

    function testSymmetrical() public {
        // Basic cases
        uint8[7] memory validSymmetrical = [10, 20, 30, 40, 30, 20, 10];
        uint8[7] memory invalidSymmetrical = [10, 20, 30, 40, 50, 20, 10];

        // Edge cases
        uint8[7] memory allSame = [50, 50, 50, 50, 50, 50, 50];
        uint8[7] memory zeroInvalid = [1, 10, 20, 30, 20, 10, 0];
        uint8[7] memory maxValid = [100, 90, 80, 70, 80, 90, 100];
        uint8[7] memory barelyAsymmetric = [10, 20, 30, 40, 30, 20, 2];

        // Test basic cases
        assertTrue(BadgeUtils.isSymmetrical(validSymmetrical, 4), "Valid symmetrical case should work");
        assertFalse(BadgeUtils.isSymmetrical(invalidSymmetrical, 4), "Invalid symmetrical case should not work");

        // Test edge cases
        assertTrue(BadgeUtils.isSymmetrical(allSame, 4), "All same values should be symmetrical");
        assertFalse(BadgeUtils.isSymmetrical(zeroInvalid, 4), "Symmetrical with zeros should work");
        assertTrue(BadgeUtils.isSymmetrical(maxValid, 4), "Symmetrical with max values should work");
        assertFalse(BadgeUtils.isSymmetrical(barelyAsymmetric, 4), "Off by one should not be symmetrical");
    }

    function testSymmetricalFuzz(uint8 midpoint) public {
        // Bound midpoint to avoid overflows when adding/subtracting
        midpoint = uint8(bound(midpoint, 7, 92));
        
        uint8[7] memory values;
        values[3] = midpoint; // Center value
        
        // Generate random variations within ±5 for the first half
        for (uint i = 0; i < 3; i++) {
            uint8 variation = uint8(bound(uint(keccak256(abi.encode(midpoint, i))), 0, 7));
            values[i] = midpoint + variation;
            // Mirror the values
            values[6-i] = values[i];
        }
        
        assertTrue(
            BadgeUtils.isSymmetrical(values, 4),
            "Symmetrical values within +/-5 should be valid"
        );
    }

    function testSymmetricalFuzzInvalid(uint8 midpoint) public {
        // Bound midpoint to avoid overflows when adding/subtracting
        midpoint = uint8(bound(midpoint, 7, 92));
        
        uint8[7] memory values;
        values[3] = midpoint; // Center value
        
        // Generate random variations within ±5 for most values
        for (uint i = 0; i < 3; i++) {
            uint8 variation = uint8(bound(uint(keccak256(abi.encode(midpoint, i))), 0, 7));
            values[i] = midpoint + variation;
            values[6-i] = values[i];
        }
        
        // Make one value asymmetric by adding more than 7
        values[6] = values[0] + 8;
        
        assertFalse(
            BadgeUtils.isSymmetrical(values, 4),
            "Asymmetrical values beyond +/-5 should be invalid"
        );
    }
}