// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title VolatilityUtils
 * @notice A library containing pattern utility functions
 */

 import "./ArrayUtils.sol";

library PatternUtils {

function countReversals(uint8[7] memory values) internal pure returns (uint8) {
    uint8 reversals = 0;
    
    // Find the first non-flat direction
    uint8 i = 0;
    while (i < 6 && values[i] == values[i + 1]) i++;
    if (i == 6) return 0; // All values are equal
    
    bool wasGoingUp = values[i + 1] > values[i];
    uint8 lastValue = values[i + 1]; // Start tracking from the first direction change
    
    // Loop through the rest of the array
    for (i = i + 2; i < 7; i++) { 
        if (values[i] == lastValue) continue; // Ignore stagnation

        bool isGoingUp = values[i] > lastValue;
        if (isGoingUp != wasGoingUp) { // Direction change detected
            reversals++;
            wasGoingUp = isGoingUp;
        }
        lastValue = values[i]; // Update lastValue after checking for reversals
    }
    
    return reversals;
}



  function getPattern(uint8[7] memory values) internal pure returns (string memory) {

    uint8 reversals = countReversals(values);
    if (isUpOnly(values)) return 'up only';
    if (isDownOnly(values)) return 'down only';
    if (isPeak(values, reversals)) return 'peak';
    if (isValley(values, reversals)) return 'valley';
    if (isUpDownUp(values, reversals)) return '\u2191\u2193\u2191';
    if (isDownUpDown(values, reversals)) return '\u2193\u2191\u2193';
    if (isWShape(values, reversals)) return '\u2193\u2191\u2193\u2191';
    if (isMShape(values, reversals)) return '\u2191\u2193\u2191\u2193';
    if (isOscillating(reversals)) return 'oscillating';
    return 'none';
  }

  function isUpOnly(uint8[7] memory values) internal pure returns (bool) {
    bool hasIncrease = false;
    for (uint8 i = 0; i < 6; i++) {
      if (values[i] > values[i + 1]) return false;
      if (values[i] < values[i + 1]) hasIncrease = true;
    }
    return hasIncrease;
  }

  function isDownOnly(uint8[7] memory values) internal pure returns (bool) {
    bool hasDecrease = false;
    for (uint8 i = 0; i < 6; i++) {
      if (values[i] < values[i + 1]) return false;
      if (values[i] > values[i + 1]) hasDecrease = true;
    }
    return hasDecrease;
  }

  function isPeak(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    if (reversals != 1) return false;
    
    // Find the peak position
    uint8 peakPos = 0;
    for (uint8 i = 0; i < 6; i++) {
        if (values[i] < values[i + 1]) {
            peakPos = i + 1;
        }
    }
    
    // Verify everything before peak is non-decreasing
    for (uint8 i = 0; i < peakPos; i++) {
        if (values[i] > values[i + 1]) return false;
    }
    
    return true;
  }

  function isValley(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    if (reversals != 1) return false;
    
    // Find the valley position
    uint8 valleyPos = 0;
    for (uint8 i = 0; i < 6; i++) {
        if (values[i] > values[i + 1]) {
            valleyPos = i + 1;
        }
    }
    
    // Verify everything before valley is non-increasing
    for (uint8 i = 0; i < valleyPos; i++) {
        if (values[i] < values[i + 1]) return false;
    }
    
    return true;
  }

  function isUpDownUp(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    if (reversals != 2) return false;
    
    // Find first non-flat direction
    uint8 i = 0;
    while (i < 6 && values[i] == values[i + 1]) i++;
    if (i == 6) return false; // All values are equal
    
    // Check if first non-flat movement is upward
    return values[i + 1] > values[i];
  }

  function isDownUpDown(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    if (reversals != 2) return false;
    
    // Find first non-flat direction
    uint8 i = 0;
    while (i < 6 && values[i] == values[i + 1]) i++;
    if (i == 6) return false; // All values are equal
    
    // Check if first non-flat movement is downward
    return values[i + 1] < values[i];
  }

function isWShape(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    if (reversals != 3) return false;

    // Find first non-flat direction
    uint8 i = 0;
    while (i < 6 && values[i] == values[i + 1]) i++;
    if (i == 6) return false; // All values are equal

    // Check if first non-flat movement is downward
    if (values[i + 1] >= values[i]) return false;

    // Find the first upward movement
    while (i < 6 && values[i] >= values[i + 1]) i++;
    if (i == 6 || values[i + 1] <= values[i]) return false;

    // Find the second downward movement
    while (i < 6 && values[i] <= values[i + 1]) i++;
    if (i == 6 || values[i + 1] >= values[i]) return false;

    // Ensure the final movement is upward
    while (i < 6 && values[i] >= values[i + 1]) i++;
    return i < 6 && values[i + 1] > values[i];
}

  function isMShape(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    if (reversals != 3) return false;

    // Find first non-flat direction
    uint8 i = 0;
    while (i < 6 && values[i] == values[i + 1]) i++;
    if (i == 6) return false; // All values are equal

    // Check if first non-flat movement is upward
    if (values[i + 1] <= values[i]) return false;

    // Find the first downward movement
    while (i < 6 && values[i] <= values[i + 1]) i++;
    if (i == 6 || values[i + 1] >= values[i]) return false;

    // Find the second upward movement
    while (i < 6 && values[i] >= values[i + 1]) i++;
    if (i == 6 || values[i + 1] <= values[i]) return false;

    // Ensure the final movement is downward
    while (i < 6 && values[i] <= values[i + 1]) i++;
    return i < 6 && values[i + 1] < values[i];
  }
  

  function isOscillating(uint8 reversals) internal pure returns (bool) {
    return reversals == 5;
  }

  function getTrend(uint8[7] memory values) internal pure returns (string memory) {
    uint8 lastValue = ArrayUtils.getLastNonZeroValue(values);
    if (lastValue > values[0]) return 'up';
    if (lastValue < values[0]) return 'down';
    return 'sideways';
  }
}