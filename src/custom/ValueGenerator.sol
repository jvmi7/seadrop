// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "./interfaces/IValueGenerator.sol";
import "./libraries/Constants.sol";
import "./libraries/ArrayUtils.sol";
import "./libraries/Utils.sol";

/**
 * @title ValueGenerator
 * @notice Generates random values using block hashes as a source of randomness
 * @dev This contract maintains a rolling array of random seeds that are updated periodically.
 *      These seeds are used to generate deterministic but unpredictable values for tokens.
 *
 */
contract ValueGenerator is IValueGenerator, Ownable {
    /*************************************/
    /*              Constants            */
    /*************************************/
    /// @notice Size of the random seeds array
    /// @dev Fixed size array to maintain recent random seeds
    uint256 private constant SEED_ARRAY_SIZE = 7;    

    /// @notice Size of the values array generated for each token
    /// @dev Must match SEED_ARRAY_SIZE for consistent generation
    uint256 private constant VALUES_ARRAY_SIZE = 7;  

    /*************************************/
    /*              Storage             */
    /*************************************/
    /// @notice Address authorized to perform automated seed updates
    /// @dev Used by Chainlink Automation for periodic updates
    address public s_upkeepAddress;

    /// @notice Address authorized to render token metadata
    /// @dev Must be set to interact with token minting and metadata
    address public _metadataRendererAddress;

    /// @notice Array of random seeds used for value generation
    /// @dev Seeds are updated in a rolling fashion, with new seeds replacing old ones
    bytes32[SEED_ARRAY_SIZE] private _randomSeeds;

    /// @notice Timestamp of the last seed update
    /// @dev Used to enforce minimum time between updates
    uint256 private _lastUpdateBlock;

    /// @notice Current update iteration number
    /// @dev Increments with each seed update, used for tracking token generations
    uint256 private _currentIteration;

    /// @notice Required time interval between seed updates
    /// @dev Defaults to Constants.DEFAULT_INTERVAL
    uint256 public _requiredInterval = Constants.DEFAULT_INTERVAL;

    /// @notice Maps token IDs to their mint iteration number
    /// @dev Used to determine which seeds were available when a token was minted
    mapping(uint256 => uint256) private _tokenMintIteration;
    
    /*************************************/
    /*              Events               */
    /*************************************/
    /// @notice Emitted when random seeds are updated
    /// @param updater Address that triggered the update
    /// @param timestamp Time of the update
    event SeedUpdated(address indexed updater, uint256 timestamp);

    /*************************************/
    /*              Errors               */
    /*************************************/
    /// @notice Thrown when block hash is invalid or zero
    error InvalidBlockHash();
    /// @notice Thrown when attempting to set invalid upkeep address
    error InvalidUpkeepAddress();
    /// @notice Thrown when update interval is invalid
    error InvalidInterval();
    /// @notice Thrown when metadata renderer address is invalid
    error InvalidMetadataRenderer();
    /// @notice Thrown when attempting to update seeds before required interval
    error InsufficientTimePassed();
    /// @notice Thrown when unauthorized address calls restricted function
    error UnauthorizedCaller();
    /// @notice Thrown when non-metadata-renderer calls restricted function
    error UnauthorizedMetadataRenderer();

    /*************************************/
    /*              Constructor          */
    /*************************************/
    /**
     * @notice Initializes the contract with the current block timestamp
     * @dev Sets initial _lastUpdateBlock to prevent immediate updates
     */
    constructor() {
        _lastUpdateBlock = block.timestamp;
    }

    /*************************************/
    /*              Modifiers            */
    /*************************************/
    /**
     * @notice Restricts function access to upkeep address or contract owner
     * @dev Used for functions that update random seeds
     */
    modifier onlyUpkeepOrOwner() {
        if (msg.sender != s_upkeepAddress && msg.sender != owner()) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /**
     * @notice Restricts function access to metadata renderer contract
     * @dev Used for functions that interact with token minting
     */
    modifier onlyMetadataRenderer() {
        if (msg.sender != _metadataRendererAddress) {
            revert UnauthorizedMetadataRenderer();
        }
        _;
    }

    /*************************************/
    /*              Getters              */
    /*************************************/
    /**
     * @notice Retrieves the current random seeds array
     * @dev External view function for reading the entire seeds array
     * @return The current random seeds array
     */
    function getRandomSeeds() external view returns (bytes32[SEED_ARRAY_SIZE] memory) {
        return _randomSeeds;
    }

    /**
     * @notice Retrieves the current iteration number
     * @dev Used to track how many seed updates have occurred
     * @return The current iteration number
     */
    function getCurrentIteration() external view returns (uint256) {
        return _currentIteration;
    }

    /**
     * @notice Retrieves the mint iteration number for a specific token
     * @dev Used to determine which seeds were available when token was minted
     * @param tokenId The ID of the token to query
     * @return The iteration number when the token was minted
     */
    function getTokenMintIteration(uint256 tokenId) external view returns (uint256) {
        return _tokenMintIteration[tokenId];
    }

    /*************************************/
    /*              Setters              */
    /*************************************/
    /**
     * @notice Sets the address authorized for automated upkeep
     * @dev Only callable by contract owner
     * @param upkeep Address of the Chainlink Automation contract
     */
    function setUpkeepAddress(address upkeep) external onlyOwner {
        if (upkeep == address(0)) revert InvalidUpkeepAddress();
        s_upkeepAddress = upkeep;
    }

    /**
     * @notice Sets the authorized metadata renderer address
     * @dev Only callable by contract owner
     * @param renderer Address of the metadata renderer contract
     */
    function setMetadataRenderer(address renderer) external onlyOwner {
        if (renderer == address(0)) revert InvalidMetadataRenderer();
        _metadataRendererAddress = renderer;
    }

    /**
     * @notice Records the iteration number when a token was minted
     * @dev Only callable by metadata renderer contract
     * @param tokenId The ID of the token being minted
     */
    function setTokenMintIteration(uint256 tokenId) external onlyMetadataRenderer {
        _tokenMintIteration[tokenId] = _currentIteration;
    }

    /*************************************/
    /*              External             */
    /*************************************/
    /**
     * @notice Updates random seeds after the required interval
     * @dev Can be called by upkeep address or owner
     *      Generates new seed, updates array, and increments iteration
     */
    function updateRandomSeeds() external onlyUpkeepOrOwner {
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastUpdate = currentTime - _lastUpdateBlock;
        
        if (timeSinceLastUpdate < _requiredInterval) {
            revert InsufficientTimePassed();
        }
        
        bytes32 newSeed = Utils.getNewRandomSeed();
        _updateRandomSeeds(newSeed);
        _lastUpdateBlock = currentTime;
        _currentIteration++;
        
        emit SeedUpdated(msg.sender, currentTime);
    }

    /**
     * @notice Generates random values for a specific token
     * @dev Values depend on token's mint iteration and current seeds
     *      Default tokens (iteration 0) use current seeds
     *      Special tokens use seeds that became available after minting
     * @param tokenId The token ID to generate values for
     * @return Array of VALUES_ARRAY_SIZE random values between 1 and MAX_RANDOM_VALUE
     */
    function generateValuesFromSeeds(uint256 tokenId) 
        external 
        view 
        returns (uint8[VALUES_ARRAY_SIZE] memory) 
    {
        uint256 mintIteration = _tokenMintIteration[tokenId];
        
        if (mintIteration == 0) {
            return _generateValuesForDefaultToken(tokenId);
        }
        
        return _generateValuesForSpecialToken(tokenId, mintIteration);
    }

    /*************************************/
    /*              Internal             */
    /*************************************/
    /**
     * @notice Updates the random seeds array with a new seed
     * @dev Either fills empty slot or shifts array and adds to end
     * @param newSeed The new seed to add to the array
     */
    function _updateRandomSeeds(bytes32 newSeed) private {
        uint256 emptySlot = ArrayUtils.findEmptySlot(_randomSeeds);
        if (emptySlot < SEED_ARRAY_SIZE) {
            _randomSeeds[emptySlot] = newSeed;
        } else {
            ArrayUtils.shiftAndUpdate(_randomSeeds, newSeed);
        }
    }

    /**
     * @notice Generates values for default tokens (iteration 0)
     * @dev Uses current seeds to generate values
     * @param tokenId The token ID to generate values for
     * @return Array of generated values
     */
    function _generateValuesForDefaultToken(uint256 tokenId) 
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
     * @notice Generates values for special tokens based on future seeds
     * @dev Uses seeds that became available after token was minted
     * @param tokenId The token ID to generate values for
     * @param mintIteration The iteration when the token was minted
     * @return Array of generated values
     */
    function _generateValuesForSpecialToken(uint256 tokenId, uint256 mintIteration) 
        private 
        view 
        returns (uint8[VALUES_ARRAY_SIZE] memory) 
    {
        uint8[VALUES_ARRAY_SIZE] memory values;
        uint256 iterationsSinceMint = _currentIteration - mintIteration;
        
        for (uint256 i = 0; i < VALUES_ARRAY_SIZE; i++) {
            if (i < iterationsSinceMint && i < VALUES_ARRAY_SIZE) {
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
     * @notice Generates a single random value from a seed and token ID
     * @dev Combines seed and tokenId to generate deterministic but random value
     * @param seed The seed to use for generation
     * @param tokenId The token ID to generate value for
     * @return Random value between 1 and MAX_RANDOM_VALUE
     */
    function _generateSingleValue(bytes32 seed, uint256 tokenId) 
        private 
        pure 
        returns (uint8) 
    {
        bytes32 combinedSeed = keccak256(abi.encodePacked(seed, tokenId));
        return uint8((uint256(combinedSeed) % Constants.MAX_RANDOM_VALUE) + 1);
    }
}