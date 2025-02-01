// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/Utils.sol";

// Test contract that can use the library
contract TestUtils {
    function testByteToHex(uint8 b) public pure returns (string memory) {
        return Utils.byteToHex(b);
    }

    function testGetNewRandomSeed() public view returns (bytes32) {
        return Utils.getNewRandomSeed();
    }

    function testAbs(uint8 a, uint8 b) public pure returns (uint8) {
        return Utils.abs(a, b);
    }
}

contract UtilsTest is Test {
    TestUtils internal utils;

    function setUp() public {
        utils = new TestUtils();
    }

    /*************************************/
    /*         byteToHex Tests           */
    /*************************************/

    function test_byteToHex_Zero() public {
        assertEq(utils.testByteToHex(0), "00");
    }

    function test_byteToHex_Max() public {
        assertEq(utils.testByteToHex(255), "ff");
    }

    function test_byteToHex_MidValue() public {
        assertEq(utils.testByteToHex(171), "ab");
    }

    function test_byteToHex_SingleDigit() public {
        assertEq(utils.testByteToHex(10), "0a");
    }

    // Fuzz test to verify random inputs
    function testFuzz_byteToHex(uint8 b) public {
        string memory result = utils.testByteToHex(b);
        assertEq(bytes(result).length, 2); // Always 2 characters
        
        // Verify it's valid hex by checking character ranges
        bytes memory resultBytes = bytes(result);
        for (uint i = 0; i < 2; i++) {
            bytes1 char = resultBytes[i];
            bool isValid = ((char >= "0" && char <= "9") || 
                          (char >= "a" && char <= "f"));
            assertTrue(isValid);
        }
    }

    /*************************************/
    /*    getNewRandomSeed Tests         */
    /*************************************/

    function test_getNewRandomSeed_Success() public {
        // Set block number to ensure we're not at block 0
        vm.roll(100);
        
        bytes32 seed = utils.testGetNewRandomSeed();
        assertTrue(seed != bytes32(0));
    }

    function test_getNewRandomSeed_AtBlockZero() public {
        // Set block number to 0
        vm.roll(0);
        
        // Expect revert with InvalidBlockHash error
        vm.expectRevert(abi.encodeWithSignature("InvalidBlockHash()"));
        utils.testGetNewRandomSeed();
    }

    /*************************************/
    /*           abs Tests               */
    /*************************************/

    function test_abs_AGreaterThanB() public {
        assertEq(utils.testAbs(10, 5), 5);
    }

    function test_abs_BGreaterThanA() public {
        assertEq(utils.testAbs(5, 10), 5);
    }

    function test_abs_Equal() public {
        assertEq(utils.testAbs(7, 7), 0);
    }

    function test_abs_Zero() public {
        assertEq(utils.testAbs(0, 5), 5);
        assertEq(utils.testAbs(5, 0), 5);
    }

    // Fuzz test to verify properties of absolute difference
    function testFuzz_abs(uint8 a, uint8 b) public {
        uint8 result = utils.testAbs(a, b);
        
        // Result should be the same regardless of parameter order
        assertEq(result, utils.testAbs(b, a));
        
        // Result should be less than or equal to max(a, b)
        assertTrue(result <= (a > b ? a : b));
        
        // If inputs are equal, result should be 0
        if (a == b) {
            assertEq(result, 0);
        }
    }
}