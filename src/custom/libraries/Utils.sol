// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Utils
 * @notice A library containing general utility functions
 */
library Utils {
    /*************************************/
    /*              Errors               */
    /*************************************/

    // @notice Thrown when block hash is invalid or zero
    error InvalidBlockHash();

    /*************************************/
    /*              Functions            */
    /*************************************/

    /**
     * @notice Converts a byte to its hex string representation
     * @param b The byte to convert
     * @return The hex string representation
     */
    function byteToHex(uint8 b) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(2);
        str[0] = hexChars[b >> 4];
        str[1] = hexChars[b & 0x0f];
        return string(str);
    }

    /**
     * @notice Retrieves the previous block hash as a random seed
     * @return The previous block hash
     */
    function generateRandomSeed() internal view returns (bytes32) {
        if (block.number == 0) revert InvalidBlockHash();

        bytes32 previousBlockHash = blockhash(block.number - 1);
        if (previousBlockHash == bytes32(0)) revert InvalidBlockHash();

        return previousBlockHash;
    }

    /**
     * @notice Generates a new seed from the previous seed and id
     * @param prevSeed The previous seed
     * @param id The id of the token
     * @return The new seed
     */
    function generateNextSeed(bytes32 prevSeed, uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(prevSeed, id));
    }

    /**
     * @notice Returns the absolute difference between two uint8 values
     * @param a The first value
     * @param b The second value
     * @return The absolute difference
     */
    function abs(uint8 a, uint8 b) internal pure returns (uint8) {
        return a >= b ? a - b : b - a;
    }
}
