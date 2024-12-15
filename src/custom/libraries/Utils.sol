// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Utils
 * @notice A library containing general utility functions
 */
library Utils {
    /**
     * @notice Converts a byte to its hex string representation
     * @param b The byte to convert
     * @return The hex string representation
     */
    function byteToHex(uint8 b) 
        internal 
        pure 
        returns (string memory) 
    {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(2);
        str[0] = hexChars[b >> 4];
        str[1] = hexChars[b & 0x0f];
        return string(str);
    }
}