// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title StakingPool
 * @dev Allows users to stake circle tokens and earn rewards
 * @notice Each circle can have its own staking pool with configurable APY
 */
contract StakingPool is ReentrancyGuard, Ownable, Pausable {
    struct StakePosition {
        uint256 amount; // Staked token amount
        uint256 stakedAt; // Timestamp when staked
        uint256 unlockAt; // Timestamp when can unstake
        uint256 lockPeriodDays; // Lock period in days (0 = flexible)
        uint256 apyMultiplier; // APY multiplier based on contributions (10000 = 1.0x)
        uint256 accruedRewards; // Accumulated rewards
        uint256 lastRewardClaim; // Last reward claim timestamp
    }

    // Constants
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant DAYS_PER_YEAR = 365;
    uint256 public constant MULTIPLIER_PRECISION = 10000;

    // Staking pool configuration
    address public circleToken; // The token being staked
    address public circleOwner; // Owner of the circle
    uint256 public baseAPY; // Base APY in basis points (e.g., 1000 = 10%)
    uint256 public totalStaked; // Total amount staked
    uint256 public rewardPool; // Available rewards in ETH

    // Lock period configs and their APY multipliers
    mapping(uint256 => uint256) public lockPeriodMultipliers; // days => multiplier

    // User staking positions
    mapping(address => StakePosition[]) public userStakes;
    mapping(address => uint256) public userTotalStaked;

    // Statistics
    uint256 public totalRewardsDistributed;
    uint256 public totalStakers;
    mapping(address => bool) public hasStaked; // Track if user has ever staked

    // Events
    event Staked(
        address indexed user,
        uint256 indexed positionId,
        uint256 amount,
        uint256 lockPeriodDays,
        uint256 apyMultiplier
    );

    event Unstaked(
        address indexed user,
        uint256 indexed positionId,
        uint256 amount,
        uint256 reward
    );

    event RewardsClaimed(
        address indexed user,
        uint256 indexed positionId,
        uint256 reward
    );

    event RewardsDeposited(uint256 amount);
    event APYUpdated(uint256 newAPY);
    event LockPeriodMultiplierSet(uint256 lockDays, uint256 multiplier);

    /**
     * @dev Constructor
     * @param _circleToken Address of the circle token to stake
     * @param _circleOwner Address of the circle owner
     * @param _baseAPY Base APY in basis points (e.g., 1000 = 10%)
     */
    constructor(
        address _circleToken,
        address _circleOwner,
        uint256 _baseAPY
    ) {
        require(_circleToken != address(0), "Invalid token");
        require(_circleOwner != address(0), "Invalid owner");
        require(_baseAPY > 0 && _baseAPY <= 10000, "Invalid APY"); // Max 100%

        circleToken = _circleToken;
        circleOwner = _circleOwner;
        baseAPY = _baseAPY;

        // Set default lock period multipliers
        lockPeriodMultipliers[0] = 10000;   // 0 days (flexible) = 1.0x
        lockPeriodMultipliers[7] = 12000;   // 7 days = 1.2x
        lockPeriodMultipliers[30] = 15000;  // 30 days = 1.5x
        lockPeriodMultipliers[90] = 20000;  // 90 days = 2.0x
    }

    /**
     * @dev Stake tokens
     * @param amount Amount of tokens to stake
     * @param lockPeriodDays Lock period in days (0 for flexible)
     * @param contributionMultiplier Multiplier based on community contribution (10000 = 1.0x)
     */
    function stake(
        uint256 amount,
        uint256 lockPeriodDays,
        uint256 contributionMultiplier
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(
            lockPeriodDays == 0 ||
            lockPeriodDays == 7 ||
            lockPeriodDays == 30 ||
            lockPeriodDays == 90,
            "Invalid lock period"
        );
        require(
            contributionMultiplier >= 10000 && contributionMultiplier <= 30000,
            "Invalid contribution multiplier"
        );

        // Transfer tokens from user
        require(
            IERC20(circleToken).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Calculate unlock time
        uint256 unlockAt = lockPeriodDays == 0
            ? block.timestamp
            : block.timestamp + (lockPeriodDays * SECONDS_PER_DAY);

        // Calculate total APY multiplier (lock period * contribution)
        uint256 lockMultiplier = lockPeriodMultipliers[lockPeriodDays];
        uint256 totalMultiplier = (lockMultiplier * contributionMultiplier) / MULTIPLIER_PRECISION;

        // Create stake position
        StakePosition memory position = StakePosition({
            amount: amount,
            stakedAt: block.timestamp,
            unlockAt: unlockAt,
            lockPeriodDays: lockPeriodDays,
            apyMultiplier: totalMultiplier,
            accruedRewards: 0,
            lastRewardClaim: block.timestamp
        });

        uint256 positionId = userStakes[msg.sender].length;
        userStakes[msg.sender].push(position);

        // Update statistics
        if (!hasStaked[msg.sender]) {
            hasStaked[msg.sender] = true;
            totalStakers++;
        }

        userTotalStaked[msg.sender] += amount;
        totalStaked += amount;

        emit Staked(msg.sender, positionId, amount, lockPeriodDays, totalMultiplier);
    }

    /**
     * @dev Unstake tokens and claim rewards
     * @param positionId Index of the stake position
     */
    function unstake(uint256 positionId) external nonReentrant {
        require(positionId < userStakes[msg.sender].length, "Invalid position");

        StakePosition storage position = userStakes[msg.sender][positionId];
        require(position.amount > 0, "Position already unstaked");
        require(block.timestamp >= position.unlockAt, "Still locked");

        // Calculate and add pending rewards
        uint256 pendingReward = calculatePendingReward(msg.sender, positionId);
        uint256 totalReward = position.accruedRewards + pendingReward;

        uint256 stakedAmount = position.amount;

        // Update statistics
        userTotalStaked[msg.sender] -= stakedAmount;
        totalStaked -= stakedAmount;

        if (totalReward > 0) {
            rewardPool -= totalReward;
            totalRewardsDistributed += totalReward;
        }

        // Clear position
        position.amount = 0;
        position.accruedRewards = 0;

        // Transfer tokens back to user
        require(
            IERC20(circleToken).transfer(msg.sender, stakedAmount),
            "Token transfer failed"
        );

        // Transfer rewards if any
        if (totalReward > 0 && rewardPool >= totalReward) {
            (bool success, ) = payable(msg.sender).call{value: totalReward}("");
            require(success, "Reward transfer failed");
        }

        emit Unstaked(msg.sender, positionId, stakedAmount, totalReward);
    }

    /**
     * @dev Claim accrued rewards without unstaking
     * @param positionId Index of the stake position
     */
    function claimRewards(uint256 positionId) external nonReentrant {
        require(positionId < userStakes[msg.sender].length, "Invalid position");

        StakePosition storage position = userStakes[msg.sender][positionId];
        require(position.amount > 0, "Position unstaked");

        uint256 pendingReward = calculatePendingReward(msg.sender, positionId);
        uint256 totalReward = position.accruedRewards + pendingReward;

        require(totalReward > 0, "No rewards to claim");
        require(rewardPool >= totalReward, "Insufficient reward pool");

        // Update position
        position.accruedRewards = 0;
        position.lastRewardClaim = block.timestamp;

        // Update statistics
        rewardPool -= totalReward;
        totalRewardsDistributed += totalReward;

        // Transfer rewards
        (bool success, ) = payable(msg.sender).call{value: totalReward}("");
        require(success, "Reward transfer failed");

        emit RewardsClaimed(msg.sender, positionId, totalReward);
    }

    /**
     * @dev Calculate pending rewards for a stake position
     * @param user Address of the user
     * @param positionId Index of the stake position
     * @return Pending reward amount in wei
     */
    function calculatePendingReward(
        address user,
        uint256 positionId
    ) public view returns (uint256) {
        if (positionId >= userStakes[user].length) return 0;

        StakePosition memory position = userStakes[user][positionId];
        if (position.amount == 0) return 0;

        uint256 stakingDuration = block.timestamp - position.lastRewardClaim;
        if (stakingDuration == 0) return 0;

        // Calculate annual reward based on APY
        uint256 effectiveAPY = (baseAPY * position.apyMultiplier) / MULTIPLIER_PRECISION;

        // Reward = (amount * effectiveAPY * duration) / (10000 * DAYS_PER_YEAR * SECONDS_PER_DAY)
        uint256 reward = (position.amount * effectiveAPY * stakingDuration)
            / (MULTIPLIER_PRECISION * DAYS_PER_YEAR * SECONDS_PER_DAY);

        return reward;
    }

    /**
     * @dev Get all stake positions for a user
     * @param user Address of the user
     * @return Array of stake positions
     */
    function getUserStakes(address user) external view returns (StakePosition[] memory) {
        return userStakes[user];
    }

    /**
     * @dev Get total rewards for a user across all positions
     * @param user Address of the user
     * @return Total pending rewards
     */
    function getUserTotalRewards(address user) external view returns (uint256) {
        uint256 totalRewards = 0;
        StakePosition[] memory positions = userStakes[user];

        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].amount > 0) {
                totalRewards += positions[i].accruedRewards + calculatePendingReward(user, i);
            }
        }

        return totalRewards;
    }

    /**
     * @dev Deposit ETH rewards into the pool
     * @notice Called by circle owner or factory to add rewards from fees
     */
    function depositRewards() external payable {
        require(msg.value > 0, "Must deposit > 0");
        rewardPool += msg.value;
        emit RewardsDeposited(msg.value);
    }

    /**
     * @dev Update base APY (only circle owner)
     * @param newAPY New base APY in basis points
     */
    function updateBaseAPY(uint256 newAPY) external {
        require(msg.sender == circleOwner, "Only circle owner");
        require(newAPY > 0 && newAPY <= 10000, "Invalid APY");

        baseAPY = newAPY;
        emit APYUpdated(newAPY);
    }

    /**
     * @dev Set lock period multiplier (only circle owner)
     * @param lockDays Lock period in days
     * @param multiplier APY multiplier (10000 = 1.0x)
     */
    function setLockPeriodMultiplier(uint256 lockDays, uint256 multiplier) external {
        require(msg.sender == circleOwner, "Only circle owner");
        require(multiplier >= 10000 && multiplier <= 30000, "Invalid multiplier");

        lockPeriodMultipliers[lockDays] = multiplier;
        emit LockPeriodMultiplierSet(lockDays, multiplier);
    }

    /**
     * @dev Emergency pause (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Get pool statistics
     * @return totalStaked_ Total staked amount
     * @return totalStakers_ Number of unique stakers
     * @return rewardPool_ Available reward pool
     * @return baseAPY_ Base APY
     */
    function getPoolStats() external view returns (
        uint256 totalStaked_,
        uint256 totalStakers_,
        uint256 rewardPool_,
        uint256 baseAPY_
    ) {
        return (totalStaked, totalStakers, rewardPool, baseAPY);
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {
        rewardPool += msg.value;
        emit RewardsDeposited(msg.value);
    }
}