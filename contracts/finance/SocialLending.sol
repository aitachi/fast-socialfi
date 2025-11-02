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
 * @title SocialLending
 * @dev Social-based lending protocol where interest rates are influenced by reputation
 * @notice Users can borrow ETH by collateralizing circle tokens
 */
contract SocialLending is ReentrancyGuard, Ownable, Pausable {
    struct LoanPosition {
        address borrower; // Borrower address
        address collateralToken; // Circle token used as collateral
        uint256 collateralAmount; // Amount of tokens collateralized
        uint256 borrowedAmount; // Amount of ETH borrowed
        uint256 interestRate; // Annual interest rate in basis points
        uint256 createdAt; // Loan creation timestamp
        uint256 lastInterestAccrual; // Last interest calculation timestamp
        uint256 accruedInterest; // Accumulated interest
        bool isActive; // Loan status
        uint256 reputationScore; // Borrower's reputation at loan creation
        address[] guarantors; // Social guarantors
        uint256 guarantorDiscount; // Interest discount from guarantors (bp)
    }

    // Constants
    uint256 public constant MIN_COLLATERAL_RATIO = 15000; // 150% minimum collateralization
    uint256 public constant LIQUIDATION_THRESHOLD = 12000; // 120% liquidation threshold
    uint256 public constant LIQUIDATION_PENALTY = 1000; // 10% penalty
    uint256 public constant BASE_INTEREST_RATE = 800; // 8% base rate
    uint256 public constant MAX_INTEREST_RATE = 2000; // 20% max rate
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    uint256 public constant PRECISION = 10000;
    uint256 public constant MAX_GUARANTOR_DISCOUNT = 500; // 5% max discount from guarantors

    // Loan tracking
    mapping(uint256 => LoanPosition) public loans;
    mapping(address => uint256[]) public userLoans;
    uint256 public nextLoanId;
    uint256 public totalBorrowed;
    uint256 public totalCollateralLocked;

    // Collateral token pricing (simplified - should use oracle in production)
    mapping(address => uint256) public tokenPrices; // token => price in wei per token

    // Reputation-based interest discount
    mapping(uint256 => uint256) public reputationDiscounts; // score tier => discount in bp

    // Platform settings
    address public platformTreasury;
    uint256 public liquidityPool; // Available ETH for lending
    uint256 public platformFee = 100; // 1% platform fee on interest

    // Events
    event LoanCreated(
        uint256 indexed loanId,
        address indexed borrower,
        address collateralToken,
        uint256 collateralAmount,
        uint256 borrowedAmount,
        uint256 interestRate
    );

    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 repaidAmount,
        uint256 interestPaid
    );

    event LoanLiquidated(
        uint256 indexed loanId,
        address indexed liquidator,
        uint256 collateralSeized,
        uint256 debtCovered
    );

    event GuarantorAdded(uint256 indexed loanId, address indexed guarantor);
    event InterestAccrued(uint256 indexed loanId, uint256 interest);
    event LiquidityDeposited(uint256 amount);
    event TokenPriceUpdated(address indexed token, uint256 price);

    /**
     * @dev Constructor
     * @param _platformTreasury Address of platform treasury
     */
    constructor(address _platformTreasury) {
        require(_platformTreasury != address(0), "Invalid treasury");
        platformTreasury = _platformTreasury;

        // Set default reputation discounts (higher score = lower rate)
        reputationDiscounts[0] = 0;      // 0-20 score: no discount
        reputationDiscounts[20] = 50;    // 20-40: 0.5% discount
        reputationDiscounts[40] = 100;   // 40-60: 1% discount
        reputationDiscounts[60] = 200;   // 60-80: 2% discount
        reputationDiscounts[80] = 300;   // 80-100: 3% discount
    }

    /**
     * @dev Borrow ETH by collateralizing circle tokens
     * @param collateralToken Address of circle token to use as collateral
     * @param collateralAmount Amount of tokens to collateralize
     * @param borrowAmount Amount of ETH to borrow
     * @param reputationScore Borrower's reputation score (0-100)
     */
    function borrow(
        address collateralToken,
        uint256 collateralAmount,
        uint256 borrowAmount,
        uint256 reputationScore
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(collateralToken != address(0), "Invalid token");
        require(collateralAmount > 0, "Collateral must be > 0");
        require(borrowAmount > 0, "Borrow amount must be > 0");
        require(reputationScore <= 100, "Invalid reputation score");
        require(liquidityPool >= borrowAmount, "Insufficient liquidity");

        // Get collateral value
        uint256 collateralValue = getCollateralValue(collateralToken, collateralAmount);
        uint256 requiredCollateral = (borrowAmount * MIN_COLLATERAL_RATIO) / PRECISION;

        require(collateralValue >= requiredCollateral, "Insufficient collateral");

        // Calculate interest rate based on reputation
        uint256 interestRate = calculateInterestRate(reputationScore, 0);

        // Transfer collateral from borrower
        require(
            IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount),
            "Collateral transfer failed"
        );

        // Create loan position
        uint256 loanId = nextLoanId++;
        loans[loanId] = LoanPosition({
            borrower: msg.sender,
            collateralToken: collateralToken,
            collateralAmount: collateralAmount,
            borrowedAmount: borrowAmount,
            interestRate: interestRate,
            createdAt: block.timestamp,
            lastInterestAccrual: block.timestamp,
            accruedInterest: 0,
            isActive: true,
            reputationScore: reputationScore,
            guarantors: new address[](0),
            guarantorDiscount: 0
        });

        userLoans[msg.sender].push(loanId);

        // Update statistics
        totalBorrowed += borrowAmount;
        totalCollateralLocked += collateralAmount;
        liquidityPool -= borrowAmount;

        // Transfer borrowed amount to borrower
        (bool success, ) = payable(msg.sender).call{value: borrowAmount}("");
        require(success, "ETH transfer failed");

        emit LoanCreated(
            loanId,
            msg.sender,
            collateralToken,
            collateralAmount,
            borrowAmount,
            interestRate
        );

        return loanId;
    }

    /**
     * @dev Repay loan and retrieve collateral
     * @param loanId ID of the loan to repay
     */
    function repay(uint256 loanId) external payable nonReentrant {
        LoanPosition storage loan = loans[loanId];
        require(loan.isActive, "Loan not active");
        require(loan.borrower == msg.sender, "Not loan owner");

        // Accrue interest
        _accrueInterest(loanId);

        uint256 totalDebt = loan.borrowedAmount + loan.accruedInterest;
        require(msg.value >= totalDebt, "Insufficient payment");

        // Calculate platform fee from interest
        uint256 platformFeePortion = (loan.accruedInterest * platformFee) / PRECISION;

        // Transfer fees
        if (platformFeePortion > 0) {
            (bool feeSuccess, ) = payable(platformTreasury).call{value: platformFeePortion}("");
            require(feeSuccess, "Fee transfer failed");
        }

        // Return to liquidity pool (principal + interest - fees)
        liquidityPool += (loan.borrowedAmount + loan.accruedInterest - platformFeePortion);

        // Update statistics
        totalBorrowed -= loan.borrowedAmount;
        totalCollateralLocked -= loan.collateralAmount;

        // Mark loan as inactive
        loan.isActive = false;

        // Return collateral to borrower
        require(
            IERC20(loan.collateralToken).transfer(msg.sender, loan.collateralAmount),
            "Collateral transfer failed"
        );

        // Refund excess payment
        if (msg.value > totalDebt) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - totalDebt}("");
            require(refundSuccess, "Refund failed");
        }

        emit LoanRepaid(loanId, msg.sender, loan.borrowedAmount, loan.accruedInterest);
    }

    /**
     * @dev Liquidate undercollateralized loan
     * @param loanId ID of the loan to liquidate
     */
    function liquidate(uint256 loanId) external payable nonReentrant {
        LoanPosition storage loan = loans[loanId];
        require(loan.isActive, "Loan not active");

        // Accrue interest
        _accrueInterest(loanId);

        // Check if loan is liquidatable
        uint256 collateralValue = getCollateralValue(loan.collateralToken, loan.collateralAmount);
        uint256 totalDebt = loan.borrowedAmount + loan.accruedInterest;
        uint256 currentRatio = (collateralValue * PRECISION) / totalDebt;

        require(currentRatio < LIQUIDATION_THRESHOLD, "Loan is healthy");

        // Calculate liquidation amounts
        uint256 penaltyAmount = (totalDebt * LIQUIDATION_PENALTY) / PRECISION;
        uint256 requiredPayment = totalDebt + penaltyAmount;

        require(msg.value >= requiredPayment, "Insufficient payment");

        // Calculate collateral to seize (including penalty)
        uint256 collateralToSeize = loan.collateralAmount;

        // Update statistics
        totalBorrowed -= loan.borrowedAmount;
        totalCollateralLocked -= loan.collateralAmount;

        // Return principal + interest to pool, penalty to liquidator
        liquidityPool += totalDebt;

        // Mark loan as inactive
        loan.isActive = false;

        // Transfer collateral to liquidator
        require(
            IERC20(loan.collateralToken).transfer(msg.sender, collateralToSeize),
            "Collateral transfer failed"
        );

        // Refund excess payment
        if (msg.value > requiredPayment) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - requiredPayment}("");
            require(refundSuccess, "Refund failed");
        }

        emit LoanLiquidated(loanId, msg.sender, collateralToSeize, totalDebt);
    }

    /**
     * @dev Add a guarantor to reduce interest rate
     * @param loanId ID of the loan
     * @param guarantor Address of the guarantor (must have high reputation)
     */
    function addGuarantor(uint256 loanId, address guarantor) external {
        LoanPosition storage loan = loans[loanId];
        require(loan.isActive, "Loan not active");
        require(loan.borrower == msg.sender, "Not loan owner");
        require(guarantor != address(0) && guarantor != msg.sender, "Invalid guarantor");
        require(loan.guarantors.length < 3, "Max guarantors reached");

        // Add guarantor
        loan.guarantors.push(guarantor);

        // Increase discount (each guarantor adds discount, max 5%)
        uint256 additionalDiscount = MAX_GUARANTOR_DISCOUNT / 3; // ~1.67% per guarantor
        loan.guarantorDiscount += additionalDiscount;
        if (loan.guarantorDiscount > MAX_GUARANTOR_DISCOUNT) {
            loan.guarantorDiscount = MAX_GUARANTOR_DISCOUNT;
        }

        // Recalculate interest rate
        loan.interestRate = calculateInterestRate(loan.reputationScore, loan.guarantorDiscount);

        emit GuarantorAdded(loanId, guarantor);
    }

    /**
     * @dev Calculate interest rate based on reputation and guarantors
     * @param reputationScore Borrower's reputation score (0-100)
     * @param guarantorDiscount Discount from guarantors in basis points
     * @return Interest rate in basis points
     */
    function calculateInterestRate(
        uint256 reputationScore,
        uint256 guarantorDiscount
    ) public view returns (uint256) {
        // Start with base rate
        uint256 rate = BASE_INTEREST_RATE;

        // Apply reputation discount
        uint256 reputationTier = (reputationScore / 20) * 20; // Round down to tier
        uint256 reputationDiscount = reputationDiscounts[reputationTier];

        if (rate > reputationDiscount) {
            rate -= reputationDiscount;
        } else {
            rate = 0;
        }

        // Apply guarantor discount
        if (rate > guarantorDiscount) {
            rate -= guarantorDiscount;
        } else {
            rate = 0;
        }

        // Ensure rate is within bounds
        if (rate > MAX_INTEREST_RATE) rate = MAX_INTEREST_RATE;

        return rate;
    }

    /**
     * @dev Get collateral value in ETH
     * @param token Address of the token
     * @param amount Amount of tokens
     * @return Value in wei
     */
    function getCollateralValue(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = tokenPrices[token];
        require(price > 0, "Token price not set");
        return (amount * price) / 1e18; // Assuming 18 decimals
    }

    /**
     * @dev Check if loan is liquidatable
     * @param loanId ID of the loan
     * @return True if loan can be liquidated
     */
    function isLiquidatable(uint256 loanId) public view returns (bool) {
        LoanPosition memory loan = loans[loanId];
        if (!loan.isActive) return false;

        uint256 collateralValue = getCollateralValue(loan.collateralToken, loan.collateralAmount);
        uint256 totalDebt = loan.borrowedAmount + _calculatePendingInterest(loanId);
        uint256 currentRatio = (collateralValue * PRECISION) / totalDebt;

        return currentRatio < LIQUIDATION_THRESHOLD;
    }

    /**
     * @dev Get loan health ratio
     * @param loanId ID of the loan
     * @return Health ratio (10000 = 100%)
     */
    function getLoanHealth(uint256 loanId) external view returns (uint256) {
        LoanPosition memory loan = loans[loanId];
        if (!loan.isActive) return 0;

        uint256 collateralValue = getCollateralValue(loan.collateralToken, loan.collateralAmount);
        uint256 totalDebt = loan.borrowedAmount + _calculatePendingInterest(loanId);

        return (collateralValue * PRECISION) / totalDebt;
    }

    /**
     * @dev Get all loans for a user
     * @param user Address of the user
     * @return Array of loan IDs
     */
    function getUserLoans(address user) external view returns (uint256[] memory) {
        return userLoans[user];
    }

    /**
     * @dev Accrue interest for a loan (internal)
     * @param loanId ID of the loan
     */
    function _accrueInterest(uint256 loanId) internal {
        LoanPosition storage loan = loans[loanId];
        if (!loan.isActive) return;

        uint256 pendingInterest = _calculatePendingInterest(loanId);

        if (pendingInterest > 0) {
            loan.accruedInterest += pendingInterest;
            loan.lastInterestAccrual = block.timestamp;
            emit InterestAccrued(loanId, pendingInterest);
        }
    }

    /**
     * @dev Calculate pending interest (view function)
     * @param loanId ID of the loan
     * @return Pending interest amount
     */
    function _calculatePendingInterest(uint256 loanId) internal view returns (uint256) {
        LoanPosition memory loan = loans[loanId];
        if (!loan.isActive) return 0;

        uint256 timeElapsed = block.timestamp - loan.lastInterestAccrual;
        if (timeElapsed == 0) return 0;

        // Interest = principal * rate * time / (PRECISION * SECONDS_PER_YEAR)
        uint256 interest = (loan.borrowedAmount * loan.interestRate * timeElapsed)
            / (PRECISION * SECONDS_PER_YEAR);

        return interest;
    }

    /**
     * @dev Set token price (oracle integration in production)
     * @param token Address of the token
     * @param price Price in wei per token
     */
    function setTokenPrice(address token, uint256 price) external onlyOwner {
        require(token != address(0), "Invalid token");
        require(price > 0, "Invalid price");

        tokenPrices[token] = price;
        emit TokenPriceUpdated(token, price);
    }

    /**
     * @dev Deposit ETH to liquidity pool
     */
    function depositLiquidity() external payable {
        require(msg.value > 0, "Must deposit > 0");
        liquidityPool += msg.value;
        emit LiquidityDeposited(msg.value);
    }

    /**
     * @dev Get lending statistics
     * @return totalBorrowed_ Total borrowed amount
     * @return liquidityPool_ Available liquidity
     * @return totalCollateralLocked_ Total collateral locked
     */
    function getLendingStats() external view returns (
        uint256 totalBorrowed_,
        uint256 liquidityPool_,
        uint256 totalCollateralLocked_
    ) {
        return (totalBorrowed, liquidityPool, totalCollateralLocked);
    }

    /**
     * @dev Pause lending (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause lending (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {
        liquidityPool += msg.value;
        emit LiquidityDeposited(msg.value);
    }
}