// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BondingCurveMath
 * @dev Library for calculating bonding curve prices
 * @notice Implements linear, exponential, and sigmoid bonding curves
 */
library BondingCurveMath {
    uint256 private constant PRECISION = 1e18;
    uint256 private constant SCALE = 1e6;

    /**
     * @dev Calculate price using linear bonding curve: price = basePrice + slope * supply
     * @param supply Current token supply
     * @param basePrice Base price in wei
     * @param slope Slope parameter (scaled by PRECISION)
     * @return price Current price in wei per token
     */
    function linearPrice(
        uint256 supply,
        uint256 basePrice,
        uint256 slope
    ) internal pure returns (uint256 price) {
        return basePrice + (supply * slope) / PRECISION;
    }

    /**
     * @dev Calculate cost to buy tokens with linear curve
     * @param supply Current supply
     * @param amount Amount of tokens to buy
     * @param basePrice Base price
     * @param slope Slope parameter
     * @return cost Total cost in wei
     */
    function linearBuyCost(
        uint256 supply,
        uint256 amount,
        uint256 basePrice,
        uint256 slope
    ) internal pure returns (uint256 cost) {
        // Cost = basePrice * amount + slope * (supply * amount + amount^2 / 2)
        uint256 baseCost = basePrice * amount;
        uint256 slopeCost = (slope * (2 * supply * amount + amount * amount)) / (2 * PRECISION);
        return baseCost + slopeCost;
    }

    /**
     * @dev Calculate refund for selling tokens with linear curve
     * @param supply Current supply (before selling)
     * @param amount Amount of tokens to sell
     * @param basePrice Base price
     * @param slope Slope parameter
     * @return refund Total refund in wei
     */
    function linearSellRefund(
        uint256 supply,
        uint256 amount,
        uint256 basePrice,
        uint256 slope
    ) internal pure returns (uint256 refund) {
        require(supply >= amount, "Insufficient supply");
        uint256 newSupply = supply - amount;
        // Refund = basePrice * amount + slope * (newSupply * amount + amount^2 / 2)
        uint256 baseRefund = basePrice * amount;
        uint256 slopeRefund = (slope * (2 * newSupply * amount + amount * amount)) / (2 * PRECISION);
        return baseRefund + slopeRefund;
    }

    /**
     * @dev Calculate price using exponential bonding curve: price = basePrice * (1 + growthRate)^supply
     * @param supply Current token supply
     * @param basePrice Base price in wei
     * @param growthRate Growth rate (scaled by PRECISION, e.g., 0.01e18 for 1%)
     * @return price Current price in wei per token
     */
    function exponentialPrice(
        uint256 supply,
        uint256 basePrice,
        uint256 growthRate
    ) internal pure returns (uint256 price) {
        if (supply == 0) return basePrice;

        // Approximate (1 + r)^n for small r using Taylor series
        // (1 + r)^n ≈ 1 + nr + n(n-1)r^2/2
        uint256 term1 = PRECISION + (supply * growthRate) / SCALE;
        uint256 term2 = (supply * (supply - 1) * growthRate * growthRate) / (2 * SCALE * SCALE * PRECISION);
        uint256 multiplier = term1 + term2;

        return (basePrice * multiplier) / PRECISION;
    }

    /**
     * @dev Calculate cost to buy tokens with exponential curve (approximation)
     * @param supply Current supply
     * @param amount Amount of tokens to buy
     * @param basePrice Base price
     * @param growthRate Growth rate parameter
     * @return cost Total cost in wei
     */
    function exponentialBuyCost(
        uint256 supply,
        uint256 amount,
        uint256 basePrice,
        uint256 growthRate
    ) internal pure returns (uint256 cost) {
        uint256 totalCost = 0;
        // Sum up the cost for each token
        for (uint256 i = 0; i < amount; i++) {
            totalCost += exponentialPrice(supply + i, basePrice, growthRate);
        }
        return totalCost;
    }

    /**
     * @dev Calculate refund for selling tokens with exponential curve
     * @param supply Current supply (before selling)
     * @param amount Amount of tokens to sell
     * @param basePrice Base price
     * @param growthRate Growth rate parameter
     * @return refund Total refund in wei
     */
    function exponentialSellRefund(
        uint256 supply,
        uint256 amount,
        uint256 basePrice,
        uint256 growthRate
    ) internal pure returns (uint256 refund) {
        require(supply >= amount, "Insufficient supply");
        uint256 totalRefund = 0;
        // Sum up the refund for each token
        for (uint256 i = 1; i <= amount; i++) {
            totalRefund += exponentialPrice(supply - i, basePrice, growthRate);
        }
        return totalRefund;
    }

    /**
     * @dev Calculate price using sigmoid bonding curve
     * @param supply Current token supply
     * @param basePrice Base price
     * @param maxPrice Maximum price
     * @param inflectionPoint Inflection point (where curve steepens)
     * @return price Current price in wei per token
     */
    function sigmoidPrice(
        uint256 supply,
        uint256 basePrice,
        uint256 maxPrice,
        uint256 inflectionPoint
    ) internal pure returns (uint256 price) {
        // Simplified sigmoid: price = basePrice + (maxPrice - basePrice) * supply / (inflectionPoint + supply)
        uint256 priceRange = maxPrice - basePrice;
        uint256 normalized = (priceRange * supply * PRECISION) / ((inflectionPoint + supply) * PRECISION);
        return basePrice + normalized;
    }

    /**
     * @dev Calculate square root (Babylonian method)
     * @param x Input value
     * @return y Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Calculate power function (x^n) using exponentiation by squaring
     * @param base Base value
     * @param exponent Exponent value
     * @return result Result of base^exponent
     */
    function power(uint256 base, uint256 exponent) internal pure returns (uint256 result) {
        result = PRECISION;
        uint256 b = base;

        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = (result * b) / PRECISION;
            }
            b = (b * b) / PRECISION;
            exponent /= 2;
        }
    }
}
