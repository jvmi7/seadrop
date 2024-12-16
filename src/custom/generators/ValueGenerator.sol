// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "../interfaces/IValueGenerator.sol";
import "../libraries/Constants.sol";

/**
 * @title ValueGenerator
 * @notice This contract generates random values using block hashes as a source of randomness
 * @dev Values are generated based on a combination of random seeds and token IDs
 */
contract ValueGenerator is IValueGenerator, Ownable {
    address public s_upkeepAddress;
    
    // Constants for array sizes
    uint256 private constant SEED_ARRAY_SIZE = 7;    
    uint256 private constant VALUES_ARRAY_SIZE = 7;  

    // State variables
    bytes32[SEED_ARRAY_SIZE] private _randomSeeds;   
    uint256 private _lastUpdateBlock;                
    uint256 private _currentIteration;
    mapping(uint256 => uint256) private _tokenMintIteration;
    uint256 public s_requiredInterval = Constants.DEFAULT_INTERVAL;

    // Custom errors
    error InvalidBlockHash();

    event SeedUpdated(address indexed updater, uint256 timestamp);

    constructor() {
        _lastUpdateBlock = block.timestamp;
    }

    function setUpkeepAddress(address upkeep) external onlyOwner {
        require(upkeep != address(0), "Invalid upkeep address");
        s_upkeepAddress = upkeep;
    }

    modifier onlyUpkeepOrOwner() {
        require(
            msg.sender == s_upkeepAddress || msg.sender == owner(),
            "Only Chainlink Automation or owner can call this"
        );
        _;
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
        
        // If not a special token, generate normally
        if (mintIteration == 0) {
            return _generateNewValues(tokenId);
        }
        
        // For special tokens, calculate values based on future seeds
        uint8[VALUES_ARRAY_SIZE] memory values;
        uint256 iterationsSinceMint = _currentIteration - mintIteration;
        
        for (uint256 i = 0; i < VALUES_ARRAY_SIZE; i++) {
            if (i < iterationsSinceMint && i < VALUES_ARRAY_SIZE) {
                // Calculate the correct index for the seed
                uint256 seedIndex = VALUES_ARRAY_SIZE - 1 - (iterationsSinceMint - 1 - i);
                if (seedIndex < VALUES_ARRAY_SIZE) {
                    bytes32 seed = _randomSeeds[seedIndex];
                    if (seed != 0) {
                        values[i] = _generateSingleValue(seed, tokenId);
                    }
                }
            }
        }
        
        return values;
    }

    /**
     * @notice Updates the random seeds after a specific time interval
     * @dev Can only be called once the interval has passed since last update
     */
    function updateDailySeeds() external onlyUpkeepOrOwner {
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastUpdate = currentTime - _lastUpdateBlock;
        
        require(
            timeSinceLastUpdate >= s_requiredInterval,
            "Not enough time has passed since last update"
        );
        
        bytes32 newSeed = _getNewRandomSeed();
        _updateRandomSeeds(newSeed);
        _lastUpdateBlock = currentTime;
        _currentIteration++;
        
        emit SeedUpdated(msg.sender, currentTime);
    }

    /**
     * @notice Returns the current array of random seeds
     * @return Array of random seeds
     */
    function getRandomSeeds() external view returns (bytes32[SEED_ARRAY_SIZE] memory) {
        return _randomSeeds;
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
     * @dev Gets a new random seed from the previous block hash
     * @return A random seed derived from the previous block hash
     */
    function _getNewRandomSeed() private view returns (bytes32) {
        if (block.number == 0) revert InvalidBlockHash();
        
        bytes32 previousBlockHash = blockhash(block.number - 1);
        if (previousBlockHash == bytes32(0)) revert InvalidBlockHash();
        
        return previousBlockHash;
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

    function setRequiredInterval(uint256 newInterval) external onlyOwner {
        require(newInterval > 0, "Interval must be greater than 0");
        s_requiredInterval = newInterval;
    }

    // TESTING FUNCTIONS
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
}