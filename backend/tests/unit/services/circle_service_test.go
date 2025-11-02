package services_test

import (
	"context"
	"errors"
	"math/big"
	"testing"

	"github.com/fast-socialfi/backend/internal/models"
	"github.com/fast-socialfi/backend/internal/service"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockCircleRepository is a mock implementation of CircleRepository
type MockCircleRepository struct {
	mock.Mock
}

func (m *MockCircleRepository) Create(ctx context.Context, circle *models.Circle) error {
	args := m.Called(ctx, circle)
	return args.Error(0)
}

func (m *MockCircleRepository) GetByID(ctx context.Context, id uint64) (*models.Circle, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Circle), args.Error(1)
}

func (m *MockCircleRepository) Update(ctx context.Context, circle *models.Circle) error {
	args := m.Called(ctx, circle)
	return args.Error(0)
}

func (m *MockCircleRepository) List(ctx context.Context, limit, offset int) ([]*models.Circle, error) {
	args := m.Called(ctx, limit, offset)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*models.Circle), args.Error(1)
}

func (m *MockCircleRepository) Count(ctx context.Context) (int64, error) {
	args := m.Called(ctx)
	return args.Get(0).(int64), args.Error(1)
}

func (m *MockCircleRepository) Search(ctx context.Context, query string, limit, offset int) ([]*models.Circle, error) {
	args := m.Called(ctx, query, limit, offset)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*models.Circle), args.Error(1)
}

func (m *MockCircleRepository) GetTrending(ctx context.Context, limit int) ([]*models.Circle, error) {
	args := m.Called(ctx, limit)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*models.Circle), args.Error(1)
}

// MockUserRepository mock
type MockUserRepository struct {
	mock.Mock
}

// MockTransactionRepository mock
type MockTransactionRepository struct {
	mock.Mock
}

// MockWeb3Service mock
type MockWeb3Service struct {
	mock.Mock
}

func (m *MockWeb3Service) CreateCircle(ctx context.Context, privateKey string, params interface{}) (string, error) {
	args := m.Called(ctx, privateKey, params)
	return args.String(0), args.Error(1)
}

func (m *MockWeb3Service) GetCircle(ctx context.Context, circleID *big.Int) (interface{}, error) {
	args := m.Called(ctx, circleID)
	return args.Get(0), args.Error(1)
}

func (m *MockWeb3Service) GetCurrentPrice(ctx context.Context, tokenAddress interface{}) (*big.Int, error) {
	args := m.Called(ctx, tokenAddress)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*big.Int), args.Error(1)
}

// TestCreateCircle_Success tests successful circle creation
func TestCreateCircle_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.CreateCircleRequest{
		Name:        "Test Circle",
		Symbol:      "TST",
		Description: "Test Description",
		CurveType:   0, // Linear
		BasePrice:   big.NewInt(1000000000000000), // 0.001 ETH
		K:           big.NewInt(1000000000000000),
		PrivateKey:  "0xtest",
	}

	expectedTxHash := "0x1234567890abcdef"

	// Expectations
	mockWeb3Svc.On("CreateCircle", ctx, req.PrivateKey, mock.Anything).Return(expectedTxHash, nil)
	mockCircleRepo.On("Create", ctx, mock.AnythingOfType("*models.Circle")).Return(nil)

	// Execute
	resp, err := svc.CreateCircle(ctx, req)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, resp)
	assert.Equal(t, expectedTxHash, resp.TxHash)
	assert.Contains(t, resp.Message, "submitted")

	mockWeb3Svc.AssertExpectations(t)
	mockCircleRepo.AssertExpectations(t)
}

// TestCreateCircle_InvalidCurveParams tests validation failure
func TestCreateCircle_InvalidCurveParams(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.CreateCircleRequest{
		Name:        "Test Circle",
		Symbol:      "TST",
		Description: "Test Description",
		CurveType:   0, // Linear
		BasePrice:   big.NewInt(1000000000000000),
		K:           big.NewInt(0), // Invalid: K must be > 0
		PrivateKey:  "0xtest",
	}

	// Execute
	resp, err := svc.CreateCircle(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, resp)
	assert.Contains(t, err.Error(), "invalid curve parameters")
}

// TestCreateCircle_BlockchainFailure tests blockchain failure
func TestCreateCircle_BlockchainFailure(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	req := &service.CreateCircleRequest{
		Name:        "Test Circle",
		Symbol:      "TST",
		Description: "Test Description",
		CurveType:   0,
		BasePrice:   big.NewInt(1000000000000000),
		K:           big.NewInt(1000000000000000),
		PrivateKey:  "0xtest",
	}

	// Expectations
	mockWeb3Svc.On("CreateCircle", ctx, req.PrivateKey, mock.Anything).
		Return("", errors.New("blockchain error"))

	// Execute
	resp, err := svc.CreateCircle(ctx, req)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, resp)
	assert.Contains(t, err.Error(), "failed to create circle on blockchain")

	mockWeb3Svc.AssertExpectations(t)
}

// TestGetCircle_Success tests successful circle retrieval
func TestGetCircle_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	circleID := uint64(1)

	expectedCircle := &models.Circle{
		ID:          circleID,
		Name:        "Test Circle",
		Symbol:      "TST",
		Description: "Test Description",
		Status:      "pending",
	}

	// Expectations
	mockCircleRepo.On("GetByID", ctx, circleID).Return(expectedCircle, nil)

	// Execute
	result, err := svc.GetCircle(ctx, circleID)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, expectedCircle, result.Circle)

	mockCircleRepo.AssertExpectations(t)
}

// TestGetCircle_NotFound tests circle not found scenario
func TestGetCircle_NotFound(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	circleID := uint64(999)

	// Expectations
	mockCircleRepo.On("GetByID", ctx, circleID).Return(nil, errors.New("not found"))

	// Execute
	result, err := svc.GetCircle(ctx, circleID)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "circle not found")

	mockCircleRepo.AssertExpectations(t)
}

// TestListCircles_Success tests successful listing
func TestListCircles_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	limit, offset := 10, 0

	expectedCircles := []*models.Circle{
		{ID: 1, Name: "Circle 1"},
		{ID: 2, Name: "Circle 2"},
	}

	// Expectations
	mockCircleRepo.On("List", ctx, limit, offset).Return(expectedCircles, nil)
	mockCircleRepo.On("Count", ctx).Return(int64(2), nil)

	// Execute
	circles, total, err := svc.ListCircles(ctx, limit, offset)

	// Assert
	assert.NoError(t, err)
	assert.Len(t, circles, 2)
	assert.Equal(t, int64(2), total)

	mockCircleRepo.AssertExpectations(t)
}

// TestSearchCircles_Success tests successful search
func TestSearchCircles_Success(t *testing.T) {
	// Setup
	mockCircleRepo := new(MockCircleRepository)
	mockUserRepo := new(MockUserRepository)
	mockTxRepo := new(MockTransactionRepository)
	mockWeb3Svc := new(MockWeb3Service)

	svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

	ctx := context.Background()
	query := "test"
	limit, offset := 10, 0

	expectedCircles := []*models.Circle{
		{ID: 1, Name: "Test Circle 1"},
	}

	// Expectations
	mockCircleRepo.On("Search", ctx, query, limit, offset).Return(expectedCircles, nil)

	// Execute
	circles, err := svc.SearchCircles(ctx, query, limit, offset)

	// Assert
	assert.NoError(t, err)
	assert.Len(t, circles, 1)

	mockCircleRepo.AssertExpectations(t)
}

// TestValidateCurveParams tests curve parameter validation
func TestValidateCurveParams(t *testing.T) {
	tests := []struct {
		name      string
		curveType uint8
		k         *big.Int
		m         *big.Int
		n         *big.Int
		wantError bool
	}{
		{
			name:      "Valid Linear",
			curveType: 0,
			k:         big.NewInt(1),
			wantError: false,
		},
		{
			name:      "Invalid Linear - K is 0",
			curveType: 0,
			k:         big.NewInt(0),
			wantError: true,
		},
		{
			name:      "Valid Exponential",
			curveType: 1,
			k:         big.NewInt(1),
			wantError: false,
		},
		{
			name:      "Valid Sigmoid",
			curveType: 2,
			k:         big.NewInt(1),
			m:         big.NewInt(1),
			n:         big.NewInt(1),
			wantError: false,
		},
		{
			name:      "Invalid Sigmoid - Missing M",
			curveType: 2,
			k:         big.NewInt(1),
			n:         big.NewInt(1),
			wantError: true,
		},
		{
			name:      "Invalid Curve Type",
			curveType: 99,
			k:         big.NewInt(1),
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockCircleRepo := new(MockCircleRepository)
			mockUserRepo := new(MockUserRepository)
			mockTxRepo := new(MockTransactionRepository)
			mockWeb3Svc := new(MockWeb3Service)

			svc := service.NewCircleService(mockCircleRepo, mockUserRepo, mockTxRepo, mockWeb3Svc)

			// We need to access the private method indirectly via CreateCircle
			ctx := context.Background()
			req := &service.CreateCircleRequest{
				Name:        "Test",
				Symbol:      "TST",
				Description: "Test",
				CurveType:   tt.curveType,
				BasePrice:   big.NewInt(1000),
				K:           tt.k,
				M:           tt.m,
				N:           tt.n,
				PrivateKey:  "0xtest",
			}

			_, err := svc.CreateCircle(ctx, req)

			if tt.wantError {
				assert.Error(t, err)
			} else {
				// We expect blockchain call to happen, so mock it
				if !tt.wantError {
					mockWeb3Svc.On("CreateCircle", ctx, req.PrivateKey, mock.Anything).
						Return("0xtxhash", nil).Maybe()
					mockCircleRepo.On("Create", ctx, mock.Anything).Return(nil).Maybe()
				}
			}
		})
	}
}
