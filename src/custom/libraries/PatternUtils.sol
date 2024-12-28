// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title VolatilityUtils
 * @notice A library containing pattern utility functions
 */

library PatternUtils {

  function countReversals(uint8[7] memory values) internal pure returns (uint256) {
    uint256 reversals = 0;
    bool wasGoingUp = values[1] > values[0];
    
    // Check each pair of numbers
    for (uint256 i = 1; i < 6; i++) {
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
    if (isUpOnly(values)) return 'up only';
    if (isDownOnly(values)) return 'down only';
    if (isPeak(values)) return 'peak';
    if (isValley(values)) return 'valley';
    if (isUpDownUp(values)) return 'up down up';
    if (isDownUpDown(values)) return 'down up down';
    if (isWShape(values)) return 'w shape';
    if (isMShape(values)) return 'm shape';
    if (isOscillating(values)) return 'oscillating';
    return 'none';
  }

  function isUpOnly(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 0 && values[1] > values[0];
  }

  function isDownOnly(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 0 && values[1] < values[0];
  }

  function isPeak(uint8[7] memory values) internal pure returns (bool) {
      return countReversals(values) == 1 && values[1] > values[0];
  }

  function isValley(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 1 && values[1] < values[0];
  }

  function isUpDownUp(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 2 && values[1] > values[0];
  }

  function isDownUpDown(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 2 && values[1] < values[0];
  }

  function isWShape(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 3 && values[1] < values[0];
  }

  function isMShape(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 3 && values[1] > values[0];
  }

  function isOscillating(uint8[7] memory values) internal pure returns (bool) {
    return countReversals(values) == 5;
  }
}