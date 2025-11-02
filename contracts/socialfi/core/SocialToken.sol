// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title SocialToken
 * @dev ERC20 Token for SocialFi Platform with governance capabilities
 *
 * Features:
 * - Standard ERC20 functionality
 * - Mintable (only by owner)
 * - Burnable
 * - Pausable (emergency situations)
 * - Voting power for governance
 * - Anti-sybil attack mechanism
 * - Gas optimized
 *
 * Total Supply: 1,000,000,000 (1 billion tokens)
 * Decimals: 18
 */
contract SocialToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit, ERC20Votes {

    // Maximum total supply (1 billion tokens)
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;

    // Token allocation percentages (basis points: 10000 = 100%)
    uint256 public constant TEAM_ALLOCATION = 2000;      // 20%
    uint256 public constant COMMUNITY_ALLOCATION = 3000; // 30%
    uint256 public constant LIQUIDITY_ALLOCATION = 2000; // 20%
    uint256 public constant STAKING_ALLOCATION = 2000;   // 20%
    uint256 public constant TREASURY_ALLOCATION = 1000;  // 10%

    // Allocation addresses
    address public teamWallet;
    address public communityWallet;
    address public liquidityWallet;
    address public stakingContract;
    address public treasuryWallet;

    // Anti-sybil mechanism
    mapping(address => uint256) public lastTransferTime;
    uint256 public constant TRANSFER_COOLDOWN = 1 seconds; // Adjustable cooldown

    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event AllocationAddressUpdated(string allocationType, address indexed newAddress);
    event EmergencyPause(address indexed by);
    event EmergencyUnpause(address indexed by);

    /**
     * @dev Constructor to initialize the SocialFi Token
     * @param initialOwner Address of the initial owner
     */
    constructor(address initialOwner)
        ERC20("SocialFi Token", "SOCIAL")
        Ownable(initialOwner)
        ERC20Permit("SocialFi Token")
    {
        // Mint initial supply to owner for distribution
        _mint(initialOwner, MAX_SUPPLY);

        emit TokensMinted(initialOwner, MAX_SUPPLY);
    }

    /**
     * @dev Set allocation addresses (one-time setup)
     * @param _teamWallet Team wallet address
     * @param _communityWallet Community wallet address
     * @param _liquidityWallet Liquidity wallet address
     * @param _stakingContract Staking contract address
     * @param _treasuryWallet Treasury wallet address
     */
    function setAllocationAddresses(
        address _teamWallet,
        address _communityWallet,
        address _liquidityWallet,
        address _stakingContract,
        address _treasuryWallet
    ) external onlyOwner {
        require(_teamWallet != address(0), "Invalid team wallet");
        require(_communityWallet != address(0), "Invalid community wallet");
        require(_liquidityWallet != address(0), "Invalid liquidity wallet");
        require(_stakingContract != address(0), "Invalid staking contract");
        require(_treasuryWallet != address(0), "Invalid treasury wallet");

        teamWallet = _teamWallet;
        communityWallet = _communityWallet;
        liquidityWallet = _liquidityWallet;
        stakingContract = _stakingContract;
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @dev Distribute tokens according to allocation
     * Can only be called once after setting allocation addresses
     */
    function distributeAllocations() external onlyOwner {
        require(teamWallet != address(0), "Allocation addresses not set");
        require(balanceOf(owner()) >= MAX_SUPPLY, "Insufficient balance for distribution");

        uint256 teamAmount = (MAX_SUPPLY * TEAM_ALLOCATION) / 10000;
        uint256 communityAmount = (MAX_SUPPLY * COMMUNITY_ALLOCATION) / 10000;
        uint256 liquidityAmount = (MAX_SUPPLY * LIQUIDITY_ALLOCATION) / 10000;
        uint256 stakingAmount = (MAX_SUPPLY * STAKING_ALLOCATION) / 10000;
        uint256 treasuryAmount = (MAX_SUPPLY * TREASURY_ALLOCATION) / 10000;

        _transfer(owner(), teamWallet, teamAmount);
        _transfer(owner(), communityWallet, communityAmount);
        _transfer(owner(), liquidityWallet, liquidityAmount);
        _transfer(owner(), stakingContract, stakingAmount);
        _transfer(owner(), treasuryWallet, treasuryAmount);
    }

    /**
     * @dev Mint new tokens (only owner, respects max supply)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Pause all token transfers (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
        emit EmergencyPause(msg.sender);
    }

    /**
     * @dev Unpause token transfers
     */
    function unpause() external onlyOwner {
        _unpause();
        emit EmergencyUnpause(msg.sender);
    }

    /**
     * @dev Anti-sybil mechanism: Apply transfer cooldown
     * @param from Sender address
     * @param to Recipient address
     * @param amount Transfer amount
     */
    function _update(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Pausable, ERC20Votes)
    {
        // Apply anti-sybil cooldown (except for minting/burning)
        if (from != address(0) && to != address(0)) {
            require(
                block.timestamp >= lastTransferTime[from] + TRANSFER_COOLDOWN,
                "Transfer cooldown active"
            );
            lastTransferTime[from] = block.timestamp;
        }

        super._update(from, to, amount);
    }

    /**
     * @dev Required override for ERC20Votes
     */
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
