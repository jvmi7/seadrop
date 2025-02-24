// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title BadgeUtils
 * @notice A library containing badge utility functions
 */

import "./ArrayUtils.sol";
import "./Utils.sol";
import "./SVGGenerator.sol";
import "./Palettes.sol";
using Utils for uint8;

library BadgeUtils {
  function isHighRoller(uint8[7] memory values) internal pure returns (bool) {
    uint8 threshold = 50;
    for (uint8 i = 0; i < 7; i++) {
        if (values[i] <= threshold) return false;
    }
    return true;
  }

  function isLowStakes(uint8[7] memory values) internal pure returns (bool) {
    uint8 threshold = 50;
    for (uint8 i = 0; i < 7; i++) {
        if (values[i] == 0) return false;
        if (values[i] >= threshold) return false;
    }
    return true;
  }

  function isRugged(uint8[7] memory values) internal pure returns (bool) {
    if (values[6] == 0) return false;
    return values[5] >= 75 && values[6] <= 5;
  }

  function isBlackSwan(uint8[7] memory values) internal pure returns (bool) {
    for (uint8 i = 1; i < 7; i++) {
      if (values[i] == 0) break;
      if (values[i-1] >= 90 && values[i] <= values[i-1] - 90) return true;
    }
    return false;
  }

  function isMoon(uint8[7] memory values) internal pure returns (bool) {
    for (uint8 i = 0; i < 6; i++) {
      if (values[i+1] == 0) break;
      if (values[i+1] >= values[i] + 90) return true;
    }
    return false;
  }

  function isComeback(uint8[7] memory values) internal pure returns (bool) {
    bool hadLowValue = false;
    
    // Check all values except the last one for any below 10
    for (uint8 i = 0; i < 6; i++) {
      if (values[i] < 10) {
        hadLowValue = true;
        break;
      }
    }
    
    // Return true if we had a low value AND the last value is above 75
    return hadLowValue && values[6] > 75;
  }

  function isRagsToRiches(uint8[7] memory values) internal pure returns (bool) {
    return values[0] < 10 && values[6] >= 90;
  }

  function isFumbled(uint8[7] memory values) internal pure returns (bool) {
    if (values[6] == 0) return false;
    return values[0] >= 90 && values[6] < 10;
  }

  function isSpike(uint8[7] memory values) internal pure returns (bool) {
    if (!ArrayUtils.areAllValuesNonZero(values)) return false;

    for (uint8 i = 0; i < 7; i++) {
      bool hasHigherSpike = true;
      for (uint8 j = 0; j < 7; j++) {
        if (i != j && values[i] <= values[j] + 50) {
          hasHigherSpike = false;
          break;
        }
      }
      if (hasHigherSpike) return true;
    }
    return false;
  }

    function isSymmetrical(uint8[7] memory values, uint8 palette) internal pure returns (bool) {
        // Check if all values are non-zero
        if (!ArrayUtils.areAllValuesNonZero(values)) return false;

        // Verify the color indices are symmetrical if the colors are determined by values
        if (Palettes.isGenesisPalette(palette) || palette == Constants.GREYSCALE) {
          uint8[7] memory colorIndices = SVGGenerator.getColorIndices(values, palette);
          if (colorIndices[0] != colorIndices[6]) return false;
          if (colorIndices[1] != colorIndices[5]) return false;
          if (colorIndices[2] != colorIndices[4]) return false;
        }
        
        // Check outer pair (index 0 and 6)
        if (Utils.abs(values[0], values[6]) > 7) return false;
        
        // Check second pair (index 1 and 5)
        if (Utils.abs(values[1], values[5]) > 7) return false;
        
        // Check third pair (index 2 and 4)
        if (Utils.abs(values[2], values[4]) > 7) return false;
        
        return true;
    }
}
