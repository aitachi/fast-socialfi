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

// CircleService handles circle business logic
type CircleService struct {
	circleRepo *repository.CircleRepository
	userRepo   *repository.UserRepository
	txRepo     *repository.TransactionRepository
	web3Svc    *web3.Web3Service
}

// NewCircleService creates a new circle service
func NewCircleService(
	circleRepo *repository.CircleRepository,
	userRepo *repository.UserRepository,
	txRepo *repository.TransactionRepository,
	web3Svc *web3.Web3Service,
) *CircleService {
	return &CircleService{
		circleRepo: circleRepo,
		userRepo:   userRepo,
		txRepo:     txRepo,
		web3Svc:    web3Svc,
	}
}

// CreateCircleRequest represents a request to create a circle
type CreateCircleRequest struct {
	Name        string   `json:"name" binding:"required,min=3,max=50"`
	Symbol      string   `json:"symbol" binding:"required,min=2,max=10"`
	Description string   `json:"description" binding:"required,max=500"`
	CurveType   uint8    `json:"curve_type" binding:"required,min=0,max=2"`
	BasePrice   *big.Int `json:"base_price" binding:"required"`
	K           *big.Int `json:"k"`
	M           *big.Int `json:"m"`
	N           *big.Int `json:"n"`
	PrivateKey  string   `json:"private_key" binding:"required"`
}

// CreateCircleResponse represents the response for circle creation
type CreateCircleResponse struct {
	CircleID      uint64 `json:"circle_id"`
	TxHash        string `json:"tx_hash"`
	TokenAddress  string `json:"token_address,omitempty"`
	Message       string `json:"message"`
}

// CreateCircle creates a new circle
func (s *CircleService) CreateCircle(ctx context.Context, req *CreateCircleRequest) (*CreateCircleResponse, error) {
	// Validate curve type parameters
	if err := s.validateCurveParams(req.CurveType, req.K, req.M, req.N); err != nil {
		return nil, fmt.Errorf("invalid curve parameters: %w", err)
	}

	// Create circle on blockchain
	txHash, err := s.web3Svc.CreateCircle(ctx, req.PrivateKey, web3.CreateCircleParams{
		Name:        req.Name,
		Symbol:      req.Symbol,
		Description: req.Description,
		CurveType:   req.CurveType,
		BasePrice:   req.BasePrice,
		K:           req.K,
		M:           req.M,
		N:           req.N,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create circle on blockchain: %w", err)
	}

	// Store in database (pending state)
	circle := &models.Circle{
		Name:        req.Name,
		Symbol:      req.Symbol,
		Description: req.Description,
		CurveType:   req.CurveType,
		Status:      "pending",
		TxHash:      txHash,
	}

	if err := s.circleRepo.Create(ctx, circle); err != nil {
		return nil, fmt.Errorf("failed to store circle: %w", err)
	}

	return &CreateCircleResponse{
		CircleID: circle.ID,
		TxHash:   txHash,
		Message:  "Circle creation transaction submitted",
	}, nil
}

// GetCircle retrieves circle information
func (s *CircleService) GetCircle(ctx context.Context, circleID uint64) (*models.CircleDetail, error) {
	// Get from database
	circle, err := s.circleRepo.GetByID(ctx, circleID)
	if err != nil {
		return nil, fmt.Errorf("circle not found: %w", err)
	}

	// If confirmed, get blockchain data
	var currentPrice *big.Int
	if circle.Status == "confirmed" && circle.TokenAddress != "" {
		tokenAddr := common.HexToAddress(circle.TokenAddress)
		currentPrice, err = s.web3Svc.GetCurrentPrice(ctx, tokenAddr)
		if err != nil {
			// Log error but don't fail
			currentPrice = big.NewInt(0)
		}
	}

	return &models.CircleDetail{
		Circle:       circle,
		CurrentPrice: currentPrice,
	}, nil
}

// ListCircles retrieves a list of circles
func (s *CircleService) ListCircles(ctx context.Context, limit, offset int) ([]*models.Circle, int64, error) {
	circles, err := s.circleRepo.List(ctx, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to list circles: %w", err)
	}

	total, err := s.circleRepo.Count(ctx)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to count circles: %w", err)
	}

	return circles, total, nil
}

// SearchCircles searches for circles
func (s *CircleService) SearchCircles(ctx context.Context, query string, limit, offset int) ([]*models.Circle, error) {
	circles, err := s.circleRepo.Search(ctx, query, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to search circles: %w", err)
	}
	return circles, nil
}

// GetTrendingCircles retrieves trending circles
func (s *CircleService) GetTrendingCircles(ctx context.Context, limit int) ([]*models.Circle, error) {
	circles, err := s.circleRepo.GetTrending(ctx, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to get trending circles: %w", err)
	}
	return circles, nil
}

// UpdateCircleFromBlockchain syncs circle data from blockchain
func (s *CircleService) UpdateCircleFromBlockchain(ctx context.Context, circleID uint64) error {
	circle, err := s.circleRepo.GetByID(ctx, circleID)
	if err != nil {
		return fmt.Errorf("circle not found: %w", err)
	}

	if circle.ChainCircleID == 0 {
		return fmt.Errorf("circle not yet confirmed on blockchain")
	}

	// Get blockchain data
	chainCircle, err := s.web3Svc.GetCircle(ctx, big.NewInt(int64(circle.ChainCircleID)))
	if err != nil {
		return fmt.Errorf("failed to get circle from blockchain: %w", err)
	}

	// Update database
	circle.OwnerAddress = chainCircle.Owner.Hex()
	circle.TokenAddress = chainCircle.TokenAddress.Hex()
	circle.BondingCurveAddress = chainCircle.BondingCurve.Hex()
	circle.Active = chainCircle.Active
	circle.Status = "confirmed"

	if err := s.circleRepo.Update(ctx, circle); err != nil {
		return fmt.Errorf("failed to update circle: %w", err)
	}

	return nil
}

// validateCurveParams validates bonding curve parameters
func (s *CircleService) validateCurveParams(curveType uint8, k, m, n *big.Int) error {
	switch curveType {
	case 0: // Linear
		if k == nil || k.Cmp(big.NewInt(0)) <= 0 {
			return fmt.Errorf("linear curve requires k > 0")
		}
	case 1: // Exponential
		if k == nil || k.Cmp(big.NewInt(0)) <= 0 {
			return fmt.Errorf("exponential curve requires k > 0")
		}
	case 2: // Sigmoid
		if k == nil || m == nil || n == nil {
			return fmt.Errorf("sigmoid curve requires k, m, and n parameters")
		}
		if k.Cmp(big.NewInt(0)) <= 0 || m.Cmp(big.NewInt(0)) <= 0 || n.Cmp(big.NewInt(0)) <= 0 {
			return fmt.Errorf("sigmoid curve parameters must be > 0")
		}
	default:
		return fmt.Errorf("invalid curve type: %d", curveType)
	}
	return nil
}
