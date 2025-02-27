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
     */
    function areAllValuesNonZero(uint8[7] memory values) internal pure returns (bool) {
        for (uint256 i = 0; i < 7; i++) {
            if (values[i] == 0) return false;
        }
        return true;
    }

    /**
     * @dev Finds the first empty (zero) slot in a bytes32 array
     * @param arr The array to search
     * @return The index of the first empty slot or array length if all slots are filled
     */
    function findEmptySlot(bytes32[7] memory arr) internal pure returns (uint256) {
        for (uint256 i = 0; i < 7; i++) {
            if (arr[i] == 0) return i;
        }
        return 7;
    }

    /**
     * @dev Shifts array elements to the left and updates the last slot with a new value
     * @param arr The array to update
     * @param newValue The new value to add at the end
     */
    function shiftAndUpdate(bytes32[7] storage arr, bytes32 newValue) internal {
        for (uint256 i = 0; i < 6; i++) {
            arr[i] = arr[i + 1];
        }
        arr[6] = newValue;
    }

    /**
     * @notice Gets the last non-zero value in a fixed-size array
     * @param values An array of 7 uint8 values to check
     * @return The last non-zero value encountered, or 0 if all values are zero
     */
    function getLastNonZeroValue(uint8[7] memory values) internal pure returns (uint8) {
        uint8 lastValue = 0;
        for (uint256 i = 0; i < 7; i++) {
            if (values[i] != 0) {
                lastValue = values[i];
            }
        }
        return lastValue;
    }
}
