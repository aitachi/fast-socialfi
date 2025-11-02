// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Staking
 * @dev Staking contract for SOCIAL tokens with multiple lock periods
 *
 * Features:
 * - Multiple lock periods (7, 30, 90 days)
 * - APY-based rewards
 * - Lock period multipliers
 * - Early unlock penalty
 * - Auto-compound option
 * - Emergency pause
 */
contract Staking is Ownable, ReentrancyGuard, Pausable {

    // SOCIAL token
    IERC20 public socialToken;

    // Base APY in basis points (1000 = 10%)
    uint256 public baseAPY = 1000; // 10%

    // Lock periods in seconds
    uint256 public constant LOCK_7_DAYS = 7 days;
    uint256 public constant LOCK_30_DAYS = 30 days;
    uint256 public constant LOCK_90_DAYS = 90 days;

    // Multipliers in basis points (10000 = 1x)
    uint256 public constant MULTIPLIER_7_DAYS = 10000;   // 1x
    uint256 public constant MULTIPLIER_30_DAYS = 15000;  // 1.5x
    uint256 public constant MULTIPLIER_90_DAYS = 20000;  // 2x

    // Early unlock penalty (2000 = 20%)
    uint256 public constant EARLY_UNLOCK_PENALTY = 2000; // 20%

    // Stake structure
    struct Stake {
        uint256 amount;
        uint256 lockPeriod;
        uint256 startTime;
        uint256 endTime;
        uint256 lastClaimTime;
        uint256 accumulatedRewards;
        bool autoCompound;
        bool active;
    }

    // Staker stakes mapping
    mapping(address => Stake[]) public stakes;

    // Total staked amount
    uint256 public totalStaked;

    // Reward pool
    uint256 public rewardPool;

    // Events
    event Staked(
        address indexed user,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 lockPeriod,
        bool autoCompound
    );
    event Unstaked(address indexed user, uint256 indexed stakeId, uint256 amount, bool earlyUnlock);
    event RewardsClaimed(address indexed user, uint256 indexed stakeId, uint256 amount);
    event RewardsCompounded(address indexed user, uint256 indexed stakeId, uint256 amount);
    event RewardPoolFunded(uint256 amount);
    event APYUpdated(uint256 oldAPY, uint256 newAPY);

    /**
     * @dev Constructor
     * @param initialOwner Initial owner address
     * @param _socialToken SOCIAL token contract address
     */
    constructor(address initialOwner, address _socialToken) Ownable(initialOwner) {
        require(_socialToken != address(0), "Invalid token address");
        socialToken = IERC20(_socialToken);
    }

    /**
     * @dev Stake tokens
     * @param amount Amount to stake
     * @param lockPeriod Lock period (7, 30, or 90 days)
     * @param autoCompound Enable auto-compounding
     */
    function stake(
        uint256 amount,
        uint256 lockPeriod,
        bool autoCompound
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(
            lockPeriod == LOCK_7_DAYS ||
            lockPeriod == LOCK_30_DAYS ||
            lockPeriod == LOCK_90_DAYS,
            "Invalid lock period"
        );

        // Transfer tokens from user
        require(
            socialToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        // Create stake
        uint256 stakeId = stakes[msg.sender].length;
        stakes[msg.sender].push(Stake({
            amount: amount,
            lockPeriod: lockPeriod,
            startTime: block.timestamp,
            endTime: block.timestamp + lockPeriod,
            lastClaimTime: block.timestamp,
            accumulatedRewards: 0,
            autoCompound: autoCompound,
            active: true
        }));

        totalStaked += amount;

        emit Staked(msg.sender, stakeId, amount, lockPeriod, autoCompound);
    }

    /**
     * @dev Unstake tokens
     * @param stakeId Stake ID
     */
    function unstake(uint256 stakeId) external nonReentrant {
        require(stakeId < stakes[msg.sender].length, "Invalid stake ID");

        Stake storage userStake = stakes[msg.sender][stakeId];
        require(userStake.active, "Stake not active");

        bool earlyUnlock = block.timestamp < userStake.endTime;
        uint256 amount = userStake.amount;
        uint256 penalty = 0;

        // Calculate pending rewards
        uint256 pendingRewards = calculatePendingRewards(msg.sender, stakeId);

        if (earlyUnlock) {
            // Apply penalty to staked amount
            penalty = (amount * EARLY_UNLOCK_PENALTY) / 10000;
            amount = amount - penalty;

            // Forfeit rewards
            pendingRewards = 0;
        }

        // Mark stake as inactive
        userStake.active = false;

        totalStaked -= userStake.amount;

        // Transfer tokens back to user
        require(socialToken.transfer(msg.sender, amount), "Transfer failed");

        // Transfer rewards if not early unlock
        if (pendingRewards > 0 && !earlyUnlock) {
            require(socialToken.transfer(msg.sender, pendingRewards), "Reward transfer failed");
        }

        // Return penalty to reward pool
        if (penalty > 0) {
            rewardPool += penalty;
        }

        emit Unstaked(msg.sender, stakeId, amount, earlyUnlock);
        if (pendingRewards > 0) {
            emit RewardsClaimed(msg.sender, stakeId, pendingRewards);
        }
    }

    /**
     * @dev Claim rewards without unstaking
     * @param stakeId Stake ID
     */
    function claimRewards(uint256 stakeId) external nonReentrant {
        require(stakeId < stakes[msg.sender].length, "Invalid stake ID");

        Stake storage userStake = stakes[msg.sender][stakeId];
        require(userStake.active, "Stake not active");

        uint256 pendingRewards = calculatePendingRewards(msg.sender, stakeId);
        require(pendingRewards > 0, "No rewards to claim");

        userStake.lastClaimTime = block.timestamp;
        userStake.accumulatedRewards += pendingRewards;

        if (userStake.autoCompound) {
            // Auto-compound: add rewards to stake amount
            userStake.amount += pendingRewards;
            totalStaked += pendingRewards;
            emit RewardsCompounded(msg.sender, stakeId, pendingRewards);
        } else {
            // Regular claim: transfer rewards to user
            require(rewardPool >= pendingRewards, "Insufficient reward pool");
            rewardPool -= pendingRewards;
            require(socialToken.transfer(msg.sender, pendingRewards), "Reward transfer failed");
            emit RewardsClaimed(msg.sender, stakeId, pendingRewards);
        }
    }

    /**
     * @dev Calculate pending rewards for a stake
     * @param user User address
     * @param stakeId Stake ID
     * @return Pending rewards amount
     */
    function calculatePendingRewards(address user, uint256 stakeId) public view returns (uint256) {
        require(stakeId < stakes[user].length, "Invalid stake ID");

        Stake memory userStake = stakes[user][stakeId];
        if (!userStake.active) {
            return 0;
        }

        uint256 stakingDuration = block.timestamp - userStake.lastClaimTime;
        uint256 multiplier = getMultiplier(userStake.lockPeriod);

        // Calculate rewards: (amount * APY * multiplier * duration) / (365 days * 10000 * 10000)
        uint256 rewards = (
            userStake.amount *
            baseAPY *
            multiplier *
            stakingDuration
        ) / (365 days * 10000 * 10000);

        return rewards;
    }

    /**
     * @dev Get multiplier for lock period
     * @param lockPeriod Lock period
     * @return Multiplier in basis points
     */
    function getMultiplier(uint256 lockPeriod) public pure returns (uint256) {
        if (lockPeriod == LOCK_7_DAYS) {
            return MULTIPLIER_7_DAYS;
        } else if (lockPeriod == LOCK_30_DAYS) {
            return MULTIPLIER_30_DAYS;
        } else if (lockPeriod == LOCK_90_DAYS) {
            return MULTIPLIER_90_DAYS;
        }
        return MULTIPLIER_7_DAYS; // Default
    }

    /**
     * @dev Get user stakes
     * @param user User address
     * @return Array of user stakes
     */
    function getUserStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }

    /**
     * @dev Get active stakes count for user
     * @param user User address
     * @return Count of active stakes
     */
    function getActiveStakesCount(address user) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < stakes[user].length; i++) {
            if (stakes[user][i].active) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Fund reward pool (only owner)
     * @param amount Amount to fund
     */
    function fundRewardPool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(
            socialToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        rewardPool += amount;
        emit RewardPoolFunded(amount);
    }

    /**
     * @dev Update base APY (only owner)
     * @param newAPY New APY in basis points
     */
    function setBaseAPY(uint256 newAPY) external onlyOwner {
        require(newAPY <= 10000, "APY too high"); // Max 100%
        uint256 oldAPY = baseAPY;
        baseAPY = newAPY;
        emit APYUpdated(oldAPY, newAPY);
    }

    /**
     * @dev Pause staking (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause staking (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Emergency withdraw (only owner, when paused)
     * @param token Token address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner whenPaused {
        require(token != address(0), "Invalid token address");
        IERC20(token).transfer(owner(), amount);
    }

    /**
     * @dev Get staking statistics
     * @return totalStaked_ Total staked amount
     * @return rewardPool_ Reward pool balance
     * @return contractBalance Contract token balance
     */
    function getStats() external view returns (
        uint256 totalStaked_,
        uint256 rewardPool_,
        uint256 contractBalance
    ) {
        totalStaked_ = totalStaked;
        rewardPool_ = rewardPool;
        contractBalance = socialToken.balanceOf(address(this));
    }
}
