// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/ArrayUtils.sol";

contract ArrayUtilsTest is Test {
    using ArrayUtils for uint8[7];
    using ArrayUtils for bytes32[7];

    bytes32[7] internal arr;

    function testAreAllValuesNonZero() public {
        // Test 1: All non-zero values
        uint8[7] memory values1 = [1, 2, 3, 4, 5, 6, 7];
        assertTrue(ArrayUtils.areAllValuesNonZero(values1));

        // Test 2: Contains a zero value
        uint8[7] memory values2 = [1, 2, 0, 4, 5, 6, 7];
        assertFalse(ArrayUtils.areAllValuesNonZero(values2));

        // Test 3: All zero values
        uint8[7] memory values3 = [0, 0, 0, 0, 0, 0, 0];
        assertFalse(ArrayUtils.areAllValuesNonZero(values3));

        // Test 4: Zero at the end
        uint8[7] memory values4 = [1, 2, 3, 4, 5, 6, 0];
        assertFalse(ArrayUtils.areAllValuesNonZero(values4));

        // Test 5: Zero at the beginning
        uint8[7] memory values5 = [0, 1, 2, 3, 4, 5, 6];
        assertFalse(ArrayUtils.areAllValuesNonZero(values5));

        // Test 6: Alternating zero and non-zero values
        uint8[7] memory values6 = [1, 0, 3, 0, 5, 0, 7];
        assertFalse(ArrayUtils.areAllValuesNonZero(values6));

        // Test 7: Single non-zero value
        uint8[7] memory values7 = [0, 0, 0, 0, 0, 0, 1];
        assertFalse(ArrayUtils.areAllValuesNonZero(values7));
    }

    function testFindEmptySlot() public {
        // Test 1: First slot empty
        bytes32[7] memory arr1 = [
            bytes32(0),
            bytes32(uint256(1)),
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6))
        ];
        assertEq(ArrayUtils.findEmptySlot(arr1), 0);

        // Test 2: Middle slot empty
        bytes32[7] memory arr2 = [
            bytes32(uint256(1)),
            bytes32(uint256(2)),
            bytes32(0),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6)),
            bytes32(uint256(7))
        ];
        assertEq(ArrayUtils.findEmptySlot(arr2), 2);

        // Test 3: No empty slots
        bytes32[7] memory arr3 = [
            bytes32(uint256(1)),
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            bytes32(uint256(4)),
            bytes32(uint256(5)),
            bytes32(uint256(6)),
            bytes32(uint256(7))
        ];
        assertEq(ArrayUtils.findEmptySlot(arr3), 7);

        // Test 4: All empty slots
        bytes32[7] memory arr4;
        assertEq(ArrayUtils.findEmptySlot(arr4), 0);
    }

    function testShiftAndUpdate() public {
        // Initialize array
        arr[0] = bytes32(uint256(1));
        arr[1] = bytes32(uint256(2));
        arr[2] = bytes32(uint256(3));
        arr[3] = bytes32(uint256(4));
        arr[4] = bytes32(uint256(5));
        arr[5] = bytes32(uint256(6));
        arr[6] = bytes32(uint256(7));

        // Test shift and update
        ArrayUtils.shiftAndUpdate(arr, bytes32(uint256(8)));

        // Verify results
        assertEq(uint256(uint256(arr[0])), 2);
        assertEq(uint256(uint256(arr[1])), 3);
        assertEq(uint256(uint256(arr[2])), 4);
        assertEq(uint256(uint256(arr[3])), 5);
        assertEq(uint256(uint256(arr[4])), 6);
        assertEq(uint256(uint256(arr[5])), 7);
        assertEq(uint256(uint256(arr[6])), 8);
    }

    function testGetLastNonZeroValue() public {
        // Test 1: All non-zero values
        uint8[7] memory values1 = [1, 2, 3, 4, 5, 6, 7];
        assertEq(ArrayUtils.getLastNonZeroValue(values1), 7);

        // Test 2: Some zero values
        uint8[7] memory values2 = [1, 0, 3, 0, 5, 0, 0];
        assertEq(ArrayUtils.getLastNonZeroValue(values2), 5);

        // Test 3: All zero values
        uint8[7] memory values3 = [0, 0, 0, 0, 0, 0, 0];
        assertEq(ArrayUtils.getLastNonZeroValue(values3), 0);

        // Test 4: Single non-zero value
        uint8[7] memory values4 = [1, 0, 0, 0, 0, 0, 0];
        assertEq(ArrayUtils.getLastNonZeroValue(values4), 1);
    }
}
