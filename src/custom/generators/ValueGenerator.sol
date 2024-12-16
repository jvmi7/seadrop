// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import "chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "../interfaces/IValueGenerator.sol";
import "../libraries/Constants.sol";

/**
 * @title ValueGenerator
 * @notice This contract generates random values using block hashes as a source of randomness
 * @dev Values are generated based on a combination of random seeds and token IDs
 */
contract ValueGenerator is IValueGenerator, VRFV2PlusWrapperConsumerBase, ConfirmedOwner {
    uint256 private constant SEED_ARRAY_SIZE = 7;    
    uint256 private constant VALUES_ARRAY_SIZE = 7;  

    bytes32[SEED_ARRAY_SIZE] private _randomSeeds;   
    uint256 private _lastUpdateBlock;                
    uint256 private _currentIteration;
    mapping(uint256 => uint256) private _tokenMintIteration;
    
    // VRF request tracking
    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // VRF configuration
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // Chainlink addresses
    address public immutable linkAddress;
    address public immutable wrapperAddress;
    
    error TooEarlyToUpdate();    

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint256 payment);

    constructor(
        address _wrapperAddress,
        address _linkAddress
    ) 
        ConfirmedOwner(msg.sender)
        VRFV2PlusWrapperConsumerBase(_wrapperAddress) 
    {
        wrapperAddress = _wrapperAddress;
        linkAddress = _linkAddress;
        _lastUpdateBlock = block.timestamp;
    }

    function updateDailySeeds() external {
        if (block.timestamp < _lastUpdateBlock + Constants.DAY_IN_SECONDS) {
            revert TooEarlyToUpdate();
        }

        // Request randomness using native payment
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
        );
        
        (uint256 requestId, uint256 reqPrice) = requestRandomnessPayInNative(
            callbackGasLimit,
            requestConfirmations,
            numWords,
            extraArgs
        );

        s_requests[requestId] = RequestStatus({
            paid: reqPrice,
            randomWords: new uint256[](0),
            fulfilled: false
        });
        
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        
        // Update seeds with the new random value
        bytes32 newSeed = bytes32(_randomWords[0]);
        _updateRandomSeeds(newSeed);
        _lastUpdateBlock = block.timestamp;
        _currentIteration++;
        
        emit RequestFulfilled(_requestId, _randomWords, s_requests[_requestId].paid);
    }

    function setTokenMintIteration(uint256 tokenId) external {
        _tokenMintIteration[tokenId] = _currentIteration;
    }

    /**
     * @notice Generates an array of random values for a specific token
     * @param tokenId The ID of the token to generate values for
     * @return An array of random values between 1 and MAX_RANDOM_VALUE
     */
    function generateValuesFromSeeds(uint256 tokenId) 
        external 
        view 
        returns (uint8[VALUES_ARRAY_SIZE] memory) 
    {
        uint256 mintIteration = _tokenMintIteration[tokenId];
        
        if (mintIteration == 0) {
            return _generateNewValues(tokenId);
        }
        
        uint256 iterationsSinceMint = _currentIteration - mintIteration;
        uint256 valuesRevealed = iterationsSinceMint;
        
        uint8[VALUES_ARRAY_SIZE] memory values = _generateNewValues(tokenId);
        
        for (uint256 i = VALUES_ARRAY_SIZE; i > valuesRevealed; i--) {
            values[i-1] = 0;
        }
        
        return values;
    }

    /**
     * @notice Returns the current array of random seeds
     * @return Array of random seeds
     */
    function getRandomSeeds() external view returns (bytes32[SEED_ARRAY_SIZE] memory) {
        return _randomSeeds;
    }

    /**
     * @notice Test function to set predetermined seeds
     * @dev Should only be used for testing purposes
     */
    function fastForwardDays() external {
        _randomSeeds[0] = 0x0000000000000000000000000000000000000000000000000000000000000001;
        _randomSeeds[1] = 0x0000000000000000000000000000000000000000000000000000000000000002;
        _randomSeeds[2] = 0x0000000000000000000000000000000000000000000000000000000000000003;
        _randomSeeds[3] = 0x0000000000000000000000000000000000000000000000000000000000000004;
        _randomSeeds[4] = 0x0000000000000000000000000000000000000000000000000000000000000005;
        _randomSeeds[5] = 0x0000000000000000000000000000000000000000000000000000000000000006;
        _randomSeeds[6] = 0x0000000000000000000000000000000000000000000000000000000000000007;

        _currentIteration+=7;
        _lastUpdateBlock = block.timestamp;
    }

    // Internal functions

    /**
     * @dev Generates an array of random values using stored seeds and token ID
     * @param tokenId The token ID to use in value generation
     * @return Array of generated random values
     */
    function _generateNewValues(uint256 tokenId) 
        private 
        view 
        returns (uint8[VALUES_ARRAY_SIZE] memory) 
    {
        uint8[VALUES_ARRAY_SIZE] memory values;
        
        for (uint256 i = 0; i < VALUES_ARRAY_SIZE; i++) {
            if (_randomSeeds[i] != 0) {
                values[i] = _generateSingleValue(_randomSeeds[i], tokenId);
            }
        }
        return values;
    }

    /**
     * @dev Generates a single random value from a seed and token ID
     * @param seed Random seed to use
     * @param tokenId Token ID to combine with seed
     * @return A random value between 1 and MAX_RANDOM_VALUE
     */
    function _generateSingleValue(bytes32 seed, uint256 tokenId) 
        private 
        pure 
        returns (uint8) 
    {
        bytes32 combinedSeed = keccak256(abi.encodePacked(seed, tokenId));
        return uint8((uint256(combinedSeed) % Constants.MAX_RANDOM_VALUE) + 1);
    }

    /**
     * @dev Updates the random seeds array with a new seed
     * @param newSeed The new seed to add to the array
     */
    function _updateRandomSeeds(bytes32 newSeed) private {
        uint256 emptySlot = _findEmptySlot();
        if (emptySlot < SEED_ARRAY_SIZE) {
            _randomSeeds[emptySlot] = newSeed;
        } else {
            _shiftAndUpdateSeeds(newSeed);
        }
    }

    /**
     * @dev Finds the first empty slot in the seeds array
     * @return Index of the first empty slot, or SEED_ARRAY_SIZE if none found
     */
    function _findEmptySlot() private view returns (uint256) {
        for (uint256 i = 0; i < SEED_ARRAY_SIZE; i++) {
            if (_randomSeeds[i] == 0) return i;
        }
        return SEED_ARRAY_SIZE;
    }

    /**
     * @dev Shifts all seeds left and adds new seed at the end
     * @param newSeed The new seed to add at the end of the array
     */
    function _shiftAndUpdateSeeds(bytes32 newSeed) private {
        for (uint256 i = 0; i < SEED_ARRAY_SIZE - 1; i++) {
            _randomSeeds[i] = _randomSeeds[i + 1];
        }
        _randomSeeds[SEED_ARRAY_SIZE - 1] = newSeed;
    }

    function getCurrentIteration() external view returns (uint256) {
        return _currentIteration;
    }
    
    function getTokenMintIteration(uint256 tokenId) external view returns (uint256) {
        return _tokenMintIteration[tokenId];
    }

    // Withdrawal functions
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function withdrawNative(uint256 amount) external onlyOwner {
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "withdrawNative failed");
    }

    receive() external payable {}
}