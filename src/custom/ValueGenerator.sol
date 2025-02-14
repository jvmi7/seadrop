// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "./interfaces/IValueGenerator.sol";
import "./libraries/Constants.sol";
import "./libraries/ArrayUtils.sol";
import "./libraries/Utils.sol";

/**
 * @title ValueGenerator
 * @notice Generates values for charts tokens
 *
 */
contract ValueGenerator is IValueGenerator, Ownable {
    /*************************************/
    /*              Constants            */
    /*************************************/
    /// @notice Size of the genesis token seeds array
    /// @dev Fixed size array to maintain recent genesis token seeds
    uint256 private constant SEED_ARRAY_SIZE = 7;

    /*************************************/
    /*              Storage             */
    /*************************************/
    /// @notice Address authorized to perform automated seed updates
    /// @dev Used by Chainlink Automation for periodic updates
    address public s_upkeepAddress;

    /// @notice Address authorized to render token metadata
    /// @dev Must be set to interact with token minting and metadata
    address public _metadataRendererAddress;

    /// @notice Array of genesis token seeds used for value generation
    /// @dev Seeds are used to generate values for tokens that were created by minting
    bytes32[SEED_ARRAY_SIZE] private _genesisTokenSeeds;

    /// @notice Random seed used for value generation for tokens created by elevation
    /// @dev Used to generate values for tokens that were created by elevation
    bytes32 private _elevatedTokenSeed;

    /// @notice Timestamp of the last seed update
    /// @dev Used to enforce minimum time between updates
    uint256 private _lastUpdateBlock;

    /// @notice Maps token IDs to their values seed
    /// @dev seed used to generate values for special tokens
    mapping(uint256 => bytes32) private _tokenValuesSeed;
    
    /*************************************/
    /*              Events               */
    /*************************************/
    /// @notice Emitted when genesis token seeds are updated
    /// @param updater Address that triggered the update
    /// @param timestamp Time of the update
    event GenesisTokenSeedsUpdated(address indexed updater, uint256 timestamp);

    /// @notice Emitted when the elevated token seed is updated
    /// @param updater Address that triggered the update
    /// @param timestamp Time of the update
    event ElevatedTokenSeedUpdated(address indexed updater, uint256 timestamp);

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
    /// @notice Thrown when the genesis token seeds array is full
    error GenesisTokenSeedsArrayFull();

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
     * @dev Used for functions that update seeds
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
     * @notice Retrieves the current genesis token seeds array
     * @dev External view function for reading the entire seeds array
     * @return The current genesis token seeds array
     */
    function getGenesisTokenSeeds() external view returns (bytes32[SEED_ARRAY_SIZE] memory) {
        return _genesisTokenSeeds;
    }

    /**
     * @notice Retrieves the seed used to generate values for a specific token
     * @dev Only callable by metadata renderer contract
     * @param tokenId The ID of the token to retrieve the seed for
     * @return The seed used to generate values for the token
     */
    function getTokenValuesSeed(uint256 tokenId) external view returns (bytes32) {
        return _tokenValuesSeed[tokenId];
    }

    /**
     * @notice Retrieves the elevated token seed
     * @return The elevated token seed
     */
    function getElevatedTokenSeed() external view returns (bytes32) {
        return _elevatedTokenSeed;
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
     * @notice Records the seed used to generate values for a special token
     * @dev Only callable by metadata renderer contract
     * @param tokenId The ID of the token being minted
     * @param seed The seed used to generate values for the token
     */
    function setTokenValuesSeed(uint256 tokenId, bytes32 seed) external onlyMetadataRenderer {
        _tokenValuesSeed[tokenId] = keccak256(abi.encodePacked(seed, _elevatedTokenSeed));
    }

    /*************************************/
    /*              External             */
    /*************************************/
    /**
     * @notice Updates genesis token seeds after the required interval
     * @dev Can be called by upkeep address or owner
     *      Generates new seed, updates array, and updates last update block
     */
    function updateGenesisTokenSeeds() external onlyUpkeepOrOwner {
        bytes32 newSeed = Utils.getNewRandomSeed();
        _updateGenesisTokenSeeds(newSeed);
        _lastUpdateBlock = block.timestamp;
        
        emit GenesisTokenSeedsUpdated(msg.sender, block.timestamp);
    }

    /**
     * @notice Updates the elevated token seed
     * @dev Only callable by upkeep address or owner
     *      Generates new seed and updates last update block
     */
    function updateElevatedTokenSeed() external onlyUpkeepOrOwner {
        bytes32 newSeed = Utils.getNewRandomSeed();
        _elevatedTokenSeed = newSeed;
        _lastUpdateBlock = block.timestamp;
        
        emit ElevatedTokenSeedUpdated(msg.sender, block.timestamp);
    }

    /**
     * @notice Simulates the elevation of a token
     * @param elevateTokenId The ID of the token being elevated
     * @param burnTokenId The ID of the token being burned
     * @return Array of SEED_ARRAY_SIZE values between 1 and MAX_RANDOM_VALUE
     */
    function simulateElevatedValues(uint256 elevateTokenId, uint256 burnTokenId) view external returns (uint8[SEED_ARRAY_SIZE] memory) {
        bytes32 tokenSeed = keccak256(abi.encodePacked(elevateTokenId, burnTokenId));
        bytes32 simulatedTokenValuesSeed = keccak256(abi.encodePacked(tokenSeed, _elevatedTokenSeed));

        uint8[SEED_ARRAY_SIZE] memory values;
        
        for (uint256 i = 0; i < SEED_ARRAY_SIZE; i++) {
            if (_genesisTokenSeeds[i] != 0) {
                values[i] = _generateSingleValue(_genesisTokenSeeds[i], simulatedTokenValuesSeed, elevateTokenId);
            }
        }
        return values;
    }

    /**
     * @notice Generates values for a specific token
     * @dev Values depend on token's mint iteration and current seeds
     * @param tokenId The token ID to generate values for
     * @return Array of SEED_ARRAY_SIZE values between 1 and MAX_RANDOM_VALUE
     */
    function generateValuesFromSeeds(uint256 tokenId) 
        external 
        view 
        returns (uint8[SEED_ARRAY_SIZE] memory) 
    {
        uint8[SEED_ARRAY_SIZE] memory values;
        
        for (uint256 i = 0; i < SEED_ARRAY_SIZE; i++) {
            if (_genesisTokenSeeds[i] != 0) {
                values[i] = _generateSingleValue(_genesisTokenSeeds[i], _tokenValuesSeed[tokenId], tokenId);
            }
        }
        return values;
    }

    /*************************************/
    /*              Internal             */
    /*************************************/
    /**
     * @notice Updates the genesis token seeds array with a new seed
     * @param newSeed The new seed to add to the array
     */
    function _updateGenesisTokenSeeds(bytes32 newSeed) private {
        uint256 emptySlot = ArrayUtils.findEmptySlot(_genesisTokenSeeds);

        if (emptySlot == SEED_ARRAY_SIZE) {
            revert GenesisTokenSeedsArrayFull();
        }

        _genesisTokenSeeds[emptySlot] = newSeed;
    }

    /**
     * @notice Generates a single value from a seed and token ID
     * @dev Combines seed and tokenId to generate deterministic but random value
     * @param genesisSeed The seed to use for generation
     * @param tokenId The token ID to generate value for
     * @return Value between 1 and MAX_RANDOM_VALUE
     */
    function _generateSingleValue(bytes32 genesisSeed, bytes32 tokenValuesSeed, uint256 tokenId) 
        private 
        pure 
        returns (uint8) 
    {
        bytes32 combinedSeed = keccak256(abi.encodePacked(genesisSeed, tokenId, tokenValuesSeed));
        return uint8((uint256(combinedSeed) % Constants.MAX_RANDOM_VALUE) + 1);
    }


    /*************************************/
    /*              Test Functions       */
    /*************************************/
    /**
     * Test function to fast forward the reveal of the first 6 tokens
     */
    function testFastForwardReveal() external {
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000001);
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000002);
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000003);
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000004);
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000005);
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000006);
        _updateGenesisTokenSeeds(0x0000000000000000000000000000000000000000000000000000000000000007);
        _lastUpdateBlock = block.timestamp;
    }
}