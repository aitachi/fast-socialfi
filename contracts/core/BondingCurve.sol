// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/BondingCurveMath.sol";
import "./CircleToken.sol";

/**
 * @title BondingCurve
 * @dev Handles token buying and selling through bonding curve pricing
 */
contract BondingCurve is ReentrancyGuard, Ownable {
    using BondingCurveMath for uint256;

    enum CurveType {
        LINEAR,
        EXPONENTIAL,
        SIGMOID
    }

    struct CurveParams {
        CurveType curveType;
        uint256 basePrice; // Base price in wei
        uint256 slope; // For linear curve
        uint256 growthRate; // For exponential curve
        uint256 maxPrice; // For sigmoid curve
        uint256 inflectionPoint; // For sigmoid curve
    }

    mapping(address => CurveParams) public curveParameters;

    address public factory;
    uint256 public constant MIN_PURCHASE = 1e15; // 0.001 ETH minimum
    uint256 public constant MAX_SLIPPAGE = 500; // 5% max slippage

    event TokensPurchased(
        address indexed token,
        address indexed buyer,
        uint256 amount,
        uint256 cost,
        uint256 newPrice
    );

    event TokensSold(
        address indexed token,
        address indexed seller,
        uint256 amount,
        uint256 refund,
        uint256 newPrice
    );

    event CurveInitialized(address indexed token, CurveType curveType);

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    constructor(address _factory) {
        require(_factory != address(0), "Invalid factory");
        factory = _factory;
        transferOwnership(_factory);
    }

    /**
     * @dev Initialize bonding curve for a token
     */
    function initializeCurve(
        address tokenAddress,
        CurveType curveType,
        uint256 basePrice,
        uint256 param1,
        uint256 param2,
        uint256 param3
    ) external onlyFactory {
        require(tokenAddress != address(0), "Invalid token");
        require(curveParameters[tokenAddress].basePrice == 0, "Already initialized");

        curveParameters[tokenAddress] = CurveParams({
            curveType: curveType,
            basePrice: basePrice,
            slope: param1,
            growthRate: param2,
            maxPrice: param3,
            inflectionPoint: param3
        });

        emit CurveInitialized(tokenAddress, curveType);
    }

    /**
     * @dev Buy tokens
     */
    function buyTokens(
        address tokenAddress,
        uint256 minTokens
    ) external payable nonReentrant returns (uint256) {
        require(msg.value >= MIN_PURCHASE, "Below minimum");
        require(tokenAddress != address(0), "Invalid token");

        CircleToken token = CircleToken(payable(tokenAddress));
        CurveParams memory params = curveParameters[tokenAddress];
        require(params.basePrice > 0, "Curve not initialized");

        uint256 currentSupply = token.totalSupply();
        uint256 tokensToMint = calculateTokensForEth(
            tokenAddress,
            msg.value,
            currentSupply
        );

        require(tokensToMint >= minTokens, "Slippage too high");

        // Calculate fees
        uint256 fee = (msg.value * token.transactionFeePercent()) / token.FEE_DENOMINATOR();
        uint256 netAmount = msg.value - fee;

        // Mint tokens
        token.mint(msg.sender, tokensToMint);

        // Add to reserve
        token.addToReserve{value: netAmount}(netAmount);

        // Collect fees
        token.collectFees{value: fee}(fee);

        // Record transaction
        token.recordTransaction(msg.value);

        uint256 newPrice = getCurrentPrice(tokenAddress);

        emit TokensPurchased(tokenAddress, msg.sender, tokensToMint, msg.value, newPrice);

        return tokensToMint;
    }

    /**
     * @dev Sell tokens
     */
    function sellTokens(
        address tokenAddress,
        uint256 amount,
        uint256 minEth
    ) external nonReentrant returns (uint256) {
        require(amount > 0, "Invalid amount");
        require(tokenAddress != address(0), "Invalid token");

        CircleToken token = CircleToken(payable(tokenAddress));
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");

        CurveParams memory params = curveParameters[tokenAddress];
        require(params.basePrice > 0, "Curve not initialized");

        uint256 currentSupply = token.totalSupply();
        uint256 ethRefund = calculateEthForTokens(tokenAddress, amount, currentSupply);

        require(ethRefund >= minEth, "Slippage too high");

        // Calculate fees
        uint256 fee = (ethRefund * token.transactionFeePercent()) / token.FEE_DENOMINATOR();
        uint256 netRefund = ethRefund - fee;

        // Burn tokens
        token.burn(msg.sender, amount);

        // Remove from reserve
        token.removeFromReserve(netRefund, msg.sender);

        // Collect fees
        if (fee > 0) {
            token.collectFees{value: fee}(fee);
        }

        // Record transaction
        token.recordTransaction(ethRefund);

        uint256 newPrice = getCurrentPrice(tokenAddress);

        emit TokensSold(tokenAddress, msg.sender, amount, netRefund, newPrice);

        return netRefund;
    }

    /**
     * @dev Calculate tokens received for ETH amount
     */
    function calculateTokensForEth(
        address tokenAddress,
        uint256 ethAmount,
        uint256 currentSupply
    ) public view returns (uint256) {
        CurveParams memory params = curveParameters[tokenAddress];

        // Binary search to find token amount
        uint256 low = 0;
        uint256 high = ethAmount * 1000; // Upper bound estimate
        uint256 tokensToMint = 0;

        while (low <= high) {
            uint256 mid = (low + high) / 2;
            uint256 cost = calculateBuyCost(tokenAddress, mid, currentSupply);

            if (cost == ethAmount) {
                return mid;
            } else if (cost < ethAmount) {
                tokensToMint = mid;
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        return tokensToMint;
    }

    /**
     * @dev Calculate ETH received for token amount
     */
    function calculateEthForTokens(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 currentSupply
    ) public view returns (uint256) {
        return calculateSellRefund(tokenAddress, tokenAmount, currentSupply);
    }

    /**
     * @dev Calculate buy cost
     */
    function calculateBuyCost(
        address tokenAddress,
        uint256 amount,
        uint256 supply
    ) public view returns (uint256) {
        CurveParams memory params = curveParameters[tokenAddress];

        if (params.curveType == CurveType.LINEAR) {
            return
                BondingCurveMath.linearBuyCost(
                    supply,
                    amount,
                    params.basePrice,
                    params.slope
                );
        } else if (params.curveType == CurveType.EXPONENTIAL) {
            return
                BondingCurveMath.exponentialBuyCost(
                    supply,
                    amount,
                    params.basePrice,
                    params.growthRate
                );
        }

        return 0;
    }

    /**
     * @dev Calculate sell refund
     */
    function calculateSellRefund(
        address tokenAddress,
        uint256 amount,
        uint256 supply
    ) public view returns (uint256) {
        CurveParams memory params = curveParameters[tokenAddress];

        if (params.curveType == CurveType.LINEAR) {
            return
                BondingCurveMath.linearSellRefund(
                    supply,
                    amount,
                    params.basePrice,
                    params.slope
                );
        } else if (params.curveType == CurveType.EXPONENTIAL) {
            return
                BondingCurveMath.exponentialSellRefund(
                    supply,
                    amount,
                    params.basePrice,
                    params.growthRate
                );
        }

        return 0;
    }

    /**
     * @dev Get current price per token
     */
    function getCurrentPrice(address tokenAddress) public view returns (uint256) {
        CircleToken token = CircleToken(payable(tokenAddress));
        uint256 supply = token.totalSupply();
        CurveParams memory params = curveParameters[tokenAddress];

        if (params.curveType == CurveType.LINEAR) {
            return BondingCurveMath.linearPrice(supply, params.basePrice, params.slope);
        } else if (params.curveType == CurveType.EXPONENTIAL) {
            return
                BondingCurveMath.exponentialPrice(supply, params.basePrice, params.growthRate);
        } else if (params.curveType == CurveType.SIGMOID) {
            return
                BondingCurveMath.sigmoidPrice(
                    supply,
                    params.basePrice,
                    params.maxPrice,
                    params.inflectionPoint
                );
        }

        return 0;
    }

    /**
     * @dev Get price impact for buying
     */
    function getBuyPriceImpact(
        address tokenAddress,
        uint256 amount
    ) external view returns (uint256 avgPrice, uint256 priceImpact) {
        CircleToken token = CircleToken(payable(tokenAddress));
        uint256 supply = token.totalSupply();

        uint256 currentPrice = getCurrentPrice(tokenAddress);
        uint256 cost = calculateBuyCost(tokenAddress, amount, supply);
        avgPrice = cost / amount;

        if (currentPrice > 0) {
            priceImpact = ((avgPrice - currentPrice) * 10000) / currentPrice;
        }
    }

    /**
     * @dev Get price impact for selling
     */
    function getSellPriceImpact(
        address tokenAddress,
        uint256 amount
    ) external view returns (uint256 avgPrice, uint256 priceImpact) {
        CircleToken token = CircleToken(payable(tokenAddress));
        uint256 supply = token.totalSupply();

        uint256 currentPrice = getCurrentPrice(tokenAddress);
        uint256 refund = calculateSellRefund(tokenAddress, amount, supply);
        avgPrice = refund / amount;

        if (currentPrice > 0) {
            priceImpact = ((currentPrice - avgPrice) * 10000) / currentPrice;
        }
    }

    /**
     * @dev Receive ETH
     */
    receive() external payable {}
}
