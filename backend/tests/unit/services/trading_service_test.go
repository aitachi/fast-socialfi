package services_test

import (
	"context"
	"errors"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/fast-socialfi/backend/internal/models"
	"github.com/fast-socialfi/backend/internal/service"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func (m *MockWeb3Service) BuyTokens(ctx context.Context, privateKey string, tokenAddr common.Address, amount, maxCost *big.Int) (string, error) {
	args := m.Called(ctx, privateKey, tokenAddr, amount, maxCost)
	return args.String(0), args.Error(1)
}

func (m *MockWeb3Service) SellTokens(ctx context.Context, privateKey string, tokenAddr common.Address, amount, minRefund *big.Int) (string, error) {
	args := m.Called(ctx, privateKey, tokenAddr, amount, minRefund)
	return args.String(0), args.Error(1)
}

func (m *MockWeb3Service) GetTokenBalance(ctx context.Context, tokenAddr, userAddr common.Address) (*big.Int, error) {
	args := m.Called(ctx, tokenAddr, userAddr)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*big.Int), args.Error(1)
}

func (m *MockTransactionRepository) Create(ctx context.Context, tx *models.Transaction) error {
	args := m.Called(ctx, tx)
	return args.Error(0)
}

// TestBuyTokens_Success tests successful token purchase
func TestBuyTokens_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.BuyTokensRequest{
		CircleID:   1,
		Amount:     big.NewInt(100),
		MaxCost:    big.NewInt(1000000000000000000), // 1 ETH
		PrivateKey: "0xtest",
	}

	circle := &models.Circle{
		ID:           1,
		Status:       "confirmed",
		Active:       true,
		TokenAddress: "0x1234567890123456789012345678901234567890",
	}

	expectedTxHash := "0xabcdef"

	// Expectations
	mockCircleRepo.On("GetByID", ctx, req.CircleID).Return(circle, nil)
	mockWeb3Svc.On("BuyTokens", ctx, req.PrivateKey, mock.Anything, req.Amount, req.MaxCost).
		Return(expectedTxHash, nil)
	mockTxRepo.On("Create", ctx, mock.AnythingOfType("*models.Transaction")).Return(nil)

	// Execute
	resp, err := svc.BuyTokens(ctx, req)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, resp)
	assert.Equal(t, expectedTxHash, resp.TxHash)
	assert.Contains(t, resp.Message, "Buy transaction submitted")

	mockCircleRepo.AssertExpectations(t)
	mockWeb3Svc.AssertExpectations(t)
	mockTxRepo.AssertExpectations(t)
}

// TestBuyTokens_CircleNotFound tests buy with non-existent circle
func TestBuyTokens_CircleNotFound(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.BuyTokensRequest{
		CircleID:   999,
		Amount:     big.NewInt(100),
		MaxCost:    big.NewInt(1000000000000000000),
		PrivateKey: "0xtest",
	}

	// Expectations
	mockCircleRepo.On("GetByID", ctx, req.CircleID).Return(nil, errors.New("not found"))

	// Execute
	resp, err := svc.BuyTokens(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, resp)
	assert.Contains(t, err.Error(), "circle not found")

	mockCircleRepo.AssertExpectations(t)
}

// TestBuyTokens_CircleNotConfirmed tests buy with unconfirmed circle
func TestBuyTokens_CircleNotConfirmed(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.BuyTokensRequest{
		CircleID:   1,
		Amount:     big.NewInt(100),
		MaxCost:    big.NewInt(1000000000000000000),
		PrivateKey: "0xtest",
	}

	circle := &models.Circle{
		ID:     1,
		Status: "pending",
	}

	// Expectations
	mockCircleRepo.On("GetByID", ctx, req.CircleID).Return(circle, nil)

	// Execute
	resp, err := svc.BuyTokens(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, resp)
	assert.Contains(t, err.Error(), "not confirmed")

	mockCircleRepo.AssertExpectations(t)
}

// TestBuyTokens_CircleNotActive tests buy with inactive circle
func TestBuyTokens_CircleNotActive(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.BuyTokensRequest{
		CircleID:   1,
		Amount:     big.NewInt(100),
		MaxCost:    big.NewInt(1000000000000000000),
		PrivateKey: "0xtest",
	}

	circle := &models.Circle{
		ID:           1,
		Status:       "confirmed",
		Active:       false,
		TokenAddress: "0x1234567890123456789012345678901234567890",
	}

	// Expectations
	mockCircleRepo.On("GetByID", ctx, req.CircleID).Return(circle, nil)

	// Execute
	resp, err := svc.BuyTokens(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, resp)
	assert.Contains(t, err.Error(), "not active")

	mockCircleRepo.AssertExpectations(t)
}

// TestSellTokens_Success tests successful token sale
func TestSellTokens_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.SellTokensRequest{
		CircleID:   1,
		Amount:     big.NewInt(50),
		MinRefund:  big.NewInt(500000000000000000), // 0.5 ETH
		PrivateKey: "0xtest",
	}

	circle := &models.Circle{
		ID:           1,
		Status:       "confirmed",
		Active:       true,
		TokenAddress: "0x1234567890123456789012345678901234567890",
	}

	expectedTxHash := "0xdef456"

	// Expectations
	mockCircleRepo.On("GetByID", ctx, req.CircleID).Return(circle, nil)
	mockWeb3Svc.On("SellTokens", ctx, req.PrivateKey, mock.Anything, req.Amount, req.MinRefund).
		Return(expectedTxHash, nil)
	mockTxRepo.On("Create", ctx, mock.AnythingOfType("*models.Transaction")).Return(nil)

	// Execute
	resp, err := svc.SellTokens(ctx, req)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, resp)
	assert.Equal(t, expectedTxHash, resp.TxHash)
	assert.Contains(t, resp.Message, "Sell transaction submitted")

	mockCircleRepo.AssertExpectations(t)
	mockWeb3Svc.AssertExpectations(t)
	mockTxRepo.AssertExpectations(t)
}

// TestGetTokenBalance_Success tests successful balance retrieval
func TestGetTokenBalance_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	circleID := uint64(1)
	userAddress := "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"

	circle := &models.Circle{
		ID:           1,
		Status:       "confirmed",
		TokenAddress: "0x1234567890123456789012345678901234567890",
	}

	expectedBalance := big.NewInt(1000)

	// Expectations
	mockCircleRepo.On("GetByID", ctx, circleID).Return(circle, nil)
	mockWeb3Svc.On("GetTokenBalance", ctx, mock.Anything, mock.Anything).Return(expectedBalance, nil)

	// Execute
	balance, err := svc.GetTokenBalance(ctx, circleID, userAddress)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, balance)
	assert.Equal(t, expectedBalance, balance)

	mockCircleRepo.AssertExpectations(t)
	mockWeb3Svc.AssertExpectations(t)
}

// TestGetCurrentPrice_Success tests successful price retrieval
func TestGetCurrentPrice_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	circleID := uint64(1)

	circle := &models.Circle{
		ID:           1,
		Status:       "confirmed",
		TokenAddress: "0x1234567890123456789012345678901234567890",
	}

	expectedPrice := big.NewInt(5000000000000000) // 0.005 ETH

	// Expectations
	mockCircleRepo.On("GetByID", ctx, circleID).Return(circle, nil)
	mockWeb3Svc.On("GetCurrentPrice", ctx, mock.Anything).Return(expectedPrice, nil)

	// Execute
	price, err := svc.GetCurrentPrice(ctx, circleID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, price)
	assert.Equal(t, expectedPrice, price)

	mockCircleRepo.AssertExpectations(t)
	mockWeb3Svc.AssertExpectations(t)
}

// TestGetTokenBalance_CircleNotConfirmed tests balance retrieval with unconfirmed circle
func TestGetTokenBalance_CircleNotConfirmed(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewTradingService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	circleID := uint64(1)
	userAddress := "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"

	circle := &models.Circle{
		ID:     1,
		Status: "pending",
	}

	// Expectations
	mockCircleRepo.On("GetByID", ctx, circleID).Return(circle, nil)

	// Execute
	balance, err := svc.GetTokenBalance(ctx, circleID, userAddress)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, balance)
	assert.Contains(t, err.Error(), "not confirmed")

	mockCircleRepo.AssertExpectations(t)
}
