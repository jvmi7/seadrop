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
    bool wasGoingUp = values[1] > values[0];
    
    // Check each pair of numbers
    for (uint8 i = 1; i < 6; i++) {
      bool isGoingUp = values[i + 1] > values[i];
      
      // If direction changed, increment reversals
      if (isGoingUp != wasGoingUp) {
        reversals++;
      }
      
      wasGoingUp = isGoingUp;
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
    for (uint8 i = 0; i < 6; i++) {
      if (values[i] > values[i + 1]) return false;
    }
    return true;
  }

  function isDownOnly(uint8[7] memory values) internal pure returns (bool) {
    for (uint8 i = 0; i < 6; i++) {
      if (values[i] < values[i + 1]) return false;
    }
    return true;
  }

  function isPeak(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
      return reversals == 1 && values[1] > values[0];
  }

  function isValley(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    return reversals == 1 && values[1] < values[0];
  }

  function isUpDownUp(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    return reversals == 2 && values[1] > values[0];
  }

  function isDownUpDown(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    return reversals == 2 && values[1] < values[0];
  }

  function isWShape(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    return reversals == 3 && values[1] < values[0];
  }

  function isMShape(uint8[7] memory values, uint8 reversals) internal pure returns (bool) {
    return reversals == 3 && values[1] > values[0];
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