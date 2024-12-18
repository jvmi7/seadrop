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
}