// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract StringAssertions {
    function assertStringStartsWith(string memory str, string memory prefix) internal pure {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);
        
        require(strBytes.length >= prefixBytes.length, "String shorter than prefix");
        
        for (uint i = 0; i < prefixBytes.length; i++) {
            require(strBytes[i] == prefixBytes[i], "String doesn't start with prefix");
        }
    }

    function assertStringContains(string memory str, string memory searchStr) internal pure {
        bytes memory strBytes = bytes(str);
        bytes memory searchBytes = bytes(searchStr);
        
        require(strBytes.length >= searchBytes.length, "String shorter than search string");
        
        bool isMatch = false;
        for (uint i = 0; i <= strBytes.length - searchBytes.length; i++) {
            bool matchFound = true;
            for (uint j = 0; j < searchBytes.length; j++) {
                if (strBytes[i + j] != searchBytes[j]) {
                    matchFound = false;
                    break;
                }
            }
            if (matchFound) {
                isMatch = true;
                break;
            }
        }
        require(isMatch, "String does not contain search string");
    }
}