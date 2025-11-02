// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package repository

import (
	"context"
	"time"

	"github.com/fast-socialfi/backend/internal/models"
	"gorm.io/gorm"
)

// UserRepository handles user data access
type UserRepository struct {
	db *gorm.DB
}

// NewUserRepository creates a new user repository
func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create creates a new user
func (r *UserRepository) Create(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

// GetByAddress retrieves a user by wallet address
func (r *UserRepository) GetByAddress(ctx context.Context, address string) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).Where("wallet_address = ?", address).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetByID retrieves a user by ID
func (r *UserRepository) GetByID(ctx context.Context, id uint64) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// Update updates user information
func (r *UserRepository) Update(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

// UpdateReputationScore updates user's reputation score
func (r *UserRepository) UpdateReputationScore(ctx context.Context, userID uint64, score int) error {
	return r.db.WithContext(ctx).Model(&models.User{}).
		Where("id = ?", userID).
		Update("reputation_score", score).Error
}

// IncrementInteractionCount increments user interaction counters
func (r *UserRepository) IncrementInteractionCount(ctx context.Context, userID uint64, field string) error {
	return r.db.WithContext(ctx).Model(&models.User{}).
		Where("id = ?", userID).
		UpdateColumn(field, gorm.Expr(field+" + ?", 1)).Error
}

// GetTopUsers retrieves top users by reputation
func (r *UserRepository) GetTopUsers(ctx context.Context, limit int) ([]*models.User, error) {
	var users []*models.User
	err := r.db.WithContext(ctx).
		Order("reputation_score DESC").
		Limit(limit).
		Find(&users).Error
	return users, err
}
