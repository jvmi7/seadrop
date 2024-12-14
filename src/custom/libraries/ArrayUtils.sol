// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ArrayUtils
 * @notice A utility library for array operations
 */
library ArrayUtils {
    /**
     * @notice Checks if all values in a fixed-size array are non-zero
     * @param values An array of 7 uint8 values to check
     * @return bool Returns true if all values are non-zero, false if any value is zero
     * @dev Iterates through a fixed array of size 7 and checks each element
     */
    function areAllValuesNonZero(uint8[7] memory values) internal pure returns (bool) {
        for (uint256 i = 0; i < 7; i++) {
            if (values[i] == 0) return false;
        }
        return true;
    }
}