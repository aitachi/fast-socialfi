package service

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/fast-socialfi/backend/internal/models"
	"github.com/fast-socialfi/backend/internal/repository"
	"github.com/fast-socialfi/backend/internal/web3"
)

// TradingService handles token trading logic
type TradingService struct {
	circleRepo *repository.CircleRepository
	userRepo   *repository.UserRepository
	txRepo     *repository.TransactionRepository
	web3Svc    *web3.Web3Service
}

// NewTradingService creates a new trading service
func NewTradingService(
	circleRepo *repository.CircleRepository,
	userRepo *repository.UserRepository,
	txRepo *repository.TransactionRepository,
	web3Svc *web3.Web3Service,
) *TradingService {
	return &TradingService{
		circleRepo: circleRepo,
		userRepo:   userRepo,
		txRepo:     txRepo,
		web3Svc:    web3Svc,
	}
}

// BuyTokensRequest represents a buy tokens request
type BuyTokensRequest struct {
	CircleID   uint64   `json:"circle_id" binding:"required"`
	Amount     *big.Int `json:"amount" binding:"required"`
	MaxCost    *big.Int `json:"max_cost" binding:"required"`
	PrivateKey string   `json:"private_key" binding:"required"`
}

// SellTokensRequest represents a sell tokens request
type SellTokensRequest struct {
	CircleID   uint64   `json:"circle_id" binding:"required"`
	Amount     *big.Int `json:"amount" binding:"required"`
	MinRefund  *big.Int `json:"min_refund" binding:"required"`
	PrivateKey string   `json:"private_key" binding:"required"`
}

// TradeResponse represents a trading response
type TradeResponse struct {
	TxHash  string `json:"tx_hash"`
	Message string `json:"message"`
}

// BuyTokens purchases circle tokens
func (s *TradingService) BuyTokens(ctx context.Context, req *BuyTokensRequest) (*TradeResponse, error) {
	// Get circle information
	circle, err := s.circleRepo.GetByID(ctx, req.CircleID)
	if err != nil {
		return nil, fmt.Errorf("circle not found: %w", err)
	}

	if circle.Status != "confirmed" {
		return nil, fmt.Errorf("circle is not confirmed yet")
	}

	if !circle.Active {
		return nil, fmt.Errorf("circle is not active")
	}

	tokenAddr := common.HexToAddress(circle.TokenAddress)

	// Execute buy on blockchain
	txHash, err := s.web3Svc.BuyTokens(ctx, req.PrivateKey, tokenAddr, req.Amount, req.MaxCost)
	if err != nil {
		return nil, fmt.Errorf("failed to buy tokens: %w", err)
	}

	// Record transaction
	tx := &models.Transaction{
		CircleID:    circle.ID,
		TxHash:      txHash,
		TxType:      "buy",
		Amount:      req.Amount.String(),
		Status:      "pending",
		TokenAddress: circle.TokenAddress,
	}

	if err := s.txRepo.Create(ctx, tx); err != nil {
		// Log error but don't fail
		fmt.Printf("failed to record transaction: %v\n", err)
	}

	return &TradeResponse{
		TxHash:  txHash,
		Message: "Buy transaction submitted successfully",
	}, nil
}

// SellTokens sells circle tokens
func (s *TradingService) SellTokens(ctx context.Context, req *SellTokensRequest) (*TradeResponse, error) {
	// Get circle information
	circle, err := s.circleRepo.GetByID(ctx, req.CircleID)
	if err != nil {
		return nil, fmt.Errorf("circle not found: %w", err)
	}

	if circle.Status != "confirmed" {
		return nil, fmt.Errorf("circle is not confirmed yet")
	}

	tokenAddr := common.HexToAddress(circle.TokenAddress)

	// Execute sell on blockchain
	txHash, err := s.web3Svc.SellTokens(ctx, req.PrivateKey, tokenAddr, req.Amount, req.MinRefund)
	if err != nil {
		return nil, fmt.Errorf("failed to sell tokens: %w", err)
	}

	// Record transaction
	tx := &models.Transaction{
		CircleID:    circle.ID,
		TxHash:      txHash,
		TxType:      "sell",
		Amount:      req.Amount.String(),
		Status:      "pending",
		TokenAddress: circle.TokenAddress,
	}

	if err := s.txRepo.Create(ctx, tx); err != nil {
		// Log error but don't fail
		fmt.Printf("failed to record transaction: %v\n", err)
	}

	return &TradeResponse{
		TxHash:  txHash,
		Message: "Sell transaction submitted successfully",
	}, nil
}

// GetTokenBalance retrieves token balance for a user
func (s *TradingService) GetTokenBalance(ctx context.Context, circleID uint64, userAddress string) (*big.Int, error) {
	circle, err := s.circleRepo.GetByID(ctx, circleID)
	if err != nil {
		return nil, fmt.Errorf("circle not found: %w", err)
	}

	if circle.Status != "confirmed" {
		return nil, fmt.Errorf("circle is not confirmed yet")
	}

	tokenAddr := common.HexToAddress(circle.TokenAddress)
	userAddr := common.HexToAddress(userAddress)

	balance, err := s.web3Svc.GetTokenBalance(ctx, tokenAddr, userAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get balance: %w", err)
	}

	return balance, nil
}

// GetCurrentPrice retrieves current token price
func (s *TradingService) GetCurrentPrice(ctx context.Context, circleID uint64) (*big.Int, error) {
	circle, err := s.circleRepo.GetByID(ctx, circleID)
	if err != nil {
		return nil, fmt.Errorf("circle not found: %w", err)
	}

	if circle.Status != "confirmed" {
		return nil, fmt.Errorf("circle is not confirmed yet")
	}

	tokenAddr := common.HexToAddress(circle.TokenAddress)

	price, err := s.web3Svc.GetCurrentPrice(ctx, tokenAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to get price: %w", err)
	}

	return price, nil
}
