// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title VolatilityUtils
 * @notice A library containing volatility utility functions
 */

library VolatilityUtils {

  function getVolatility(uint8[7] memory values) internal pure returns (string memory) {
    uint256 sumOfChanges = 0;
    
    // Calculate sum of absolute differences between consecutive values
    for (uint256 i = 1; i < values.length; i++) {
        if (values[i] >= values[i-1]) {
            sumOfChanges += values[i] - values[i-1];
        } else {
            sumOfChanges += values[i-1] - values[i];
        }
    }
    
    if (sumOfChanges < 115) return 'very low';
    if (sumOfChanges < 165) return 'low';
    if (sumOfChanges < 230) return 'medium';
    if (sumOfChanges < 295) return 'high';
    return 'very high';
  }

}