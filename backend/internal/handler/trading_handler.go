package handler

import (
	"net/http"
	"strconv"

	"github.com/fast-socialfi/backend/internal/service"
	"github.com/gin-gonic/gin"
)

// TradingHandler handles trading-related HTTP requests
type TradingHandler struct {
	tradingSvc *service.TradingService
}

// NewTradingHandler creates a new trading handler
func NewTradingHandler(tradingSvc *service.TradingService) *TradingHandler {
	return &TradingHandler{
		tradingSvc: tradingSvc,
	}
}

// RegisterRoutes registers trading routes
func (h *TradingHandler) RegisterRoutes(r *gin.RouterGroup) {
	trading := r.Group("/trading")
	{
		trading.POST("/buy", h.BuyTokens)
		trading.POST("/sell", h.SellTokens)
		trading.GET("/balance/:circleId/:address", h.GetTokenBalance)
		trading.GET("/price/:circleId", h.GetCurrentPrice)
	}
}

// BuyTokens godoc
// @Summary Buy circle tokens
// @Description Purchases tokens from a circle using bonding curve
// @Tags trading
// @Accept json
// @Produce json
// @Param request body service.BuyTokensRequest true "Buy tokens request"
// @Success 200 {object} service.TradeResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/trading/buy [post]
func (h *TradingHandler) BuyTokens(c *gin.Context) {
	var req service.BuyTokensRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
		})
		return
	}

	resp, err := h.tradingSvc.BuyTokens(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to buy tokens",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// SellTokens godoc
// @Summary Sell circle tokens
// @Description Sells tokens back to a circle using bonding curve
// @Tags trading
// @Accept json
// @Produce json
// @Param request body service.SellTokensRequest true "Sell tokens request"
// @Success 200 {object} service.TradeResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/trading/sell [post]
func (h *TradingHandler) SellTokens(c *gin.Context) {
	var req service.SellTokensRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Message: err.Error(),
		})
		return
	}

	resp, err := h.tradingSvc.SellTokens(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to sell tokens",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// GetTokenBalance godoc
// @Summary Get token balance
// @Description Retrieves token balance for a user in a specific circle
// @Tags trading
// @Produce json
// @Param circleId path int true "Circle ID"
// @Param address path string true "User wallet address"
// @Success 200 {object} BalanceResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/trading/balance/{circleId}/{address} [get]
func (h *TradingHandler) GetTokenBalance(c *gin.Context) {
	circleID, err := strconv.ParseUint(c.Param("circleId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid circle ID",
			Message: err.Error(),
		})
		return
	}

	address := c.Param("address")
	if address == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Message: "Address is required",
		})
		return
	}

	balance, err := h.tradingSvc.GetTokenBalance(c.Request.Context(), circleID, address)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to get balance",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, BalanceResponse{
		CircleID: circleID,
		Address:  address,
		Balance:  balance.String(),
	})
}

// GetCurrentPrice godoc
// @Summary Get current token price
// @Description Retrieves current price for a circle's tokens
// @Tags trading
// @Produce json
// @Param circleId path int true "Circle ID"
// @Success 200 {object} PriceResponse
// @Failure 400 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /api/v1/trading/price/{circleId} [get]
func (h *TradingHandler) GetCurrentPrice(c *gin.Context) {
	circleID, err := strconv.ParseUint(c.Param("circleId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid circle ID",
			Message: err.Error(),
		})
		return
	}

	price, err := h.tradingSvc.GetCurrentPrice(c.Request.Context(), circleID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ErrorResponse{
			Error:   "Failed to get price",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, PriceResponse{
		CircleID: circleID,
		Price:    price.String(),
	})
}

// Response types
type BalanceResponse struct {
	CircleID uint64 `json:"circle_id"`
	Address  string `json:"address"`
	Balance  string `json:"balance"`
}

type PriceResponse struct {
	CircleID uint64 `json:"circle_id"`
	Price    string `json:"price"`
}
