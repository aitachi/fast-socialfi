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

// CircleRepository handles circle data access
type CircleRepository struct {
	db *gorm.DB
}

// NewCircleRepository creates a new circle repository
func NewCircleRepository(db *gorm.DB) *CircleRepository {
	return &CircleRepository{db: db}
}

// Create creates a new circle
func (r *CircleRepository) Create(ctx context.Context, circle *models.Circle) error {
	return r.db.WithContext(ctx).Create(circle).Error
}

// GetByID retrieves a circle by ID
func (r *CircleRepository) GetByID(ctx context.Context, id uint64) (*models.Circle, error) {
	var circle models.Circle
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&circle).Error
	if err != nil {
		return nil, err
	}
	return &circle, nil
}

// GetByChainID retrieves a circle by blockchain circle ID
func (r *CircleRepository) GetByChainID(ctx context.Context, chainCircleID uint64) (*models.Circle, error) {
	var circle models.Circle
	err := r.db.WithContext(ctx).Where("chain_circle_id = ?", chainCircleID).First(&circle).Error
	if err != nil {
		return nil, err
	}
	return &circle, nil
}

// GetByOwner retrieves circles owned by a user
func (r *CircleRepository) GetByOwner(ctx context.Context, ownerAddress string, limit, offset int) ([]*models.Circle, error) {
	var circles []*models.Circle
	err := r.db.WithContext(ctx).
		Where("owner_address = ?", ownerAddress).
		Limit(limit).
		Offset(offset).
		Order("created_at DESC").
		Find(&circles).Error
	return circles, err
}

// List retrieves circles with pagination
func (r *CircleRepository) List(ctx context.Context, limit, offset int) ([]*models.Circle, error) {
	var circles []*models.Circle
	err := r.db.WithContext(ctx).
		Limit(limit).
		Offset(offset).
		Order("created_at DESC").
		Find(&circles).Error
	return circles, err
}

// Update updates circle information
func (r *CircleRepository) Update(ctx context.Context, circle *models.Circle) error {
	return r.db.WithContext(ctx).Save(circle).Error
}

// UpdateStats updates circle statistics
func (r *CircleRepository) UpdateStats(ctx context.Context, circleID uint64, stats *models.CircleStats) error {
	return r.db.WithContext(ctx).Model(&models.Circle{}).
		Where("id = ?", circleID).
		Updates(map[string]interface{}{
			"total_supply":    stats.TotalSupply,
			"holder_count":    stats.HolderCount,
			"transaction_count": stats.TransactionCount,
			"total_volume":    stats.TotalVolume,
			"updated_at":      time.Now(),
		}).Error
}

// Search searches circles by name or symbol
func (r *CircleRepository) Search(ctx context.Context, query string, limit, offset int) ([]*models.Circle, error) {
	var circles []*models.Circle
	err := r.db.WithContext(ctx).
		Where("name LIKE ? OR symbol LIKE ?", "%"+query+"%", "%"+query+"%").
		Limit(limit).
		Offset(offset).
		Order("holder_count DESC").
		Find(&circles).Error
	return circles, err
}

// GetTrending retrieves trending circles
func (r *CircleRepository) GetTrending(ctx context.Context, limit int) ([]*models.Circle, error) {
	var circles []*models.Circle

	// Get circles with highest transaction volume in last 24 hours
	yesterday := time.Now().Add(-24 * time.Hour)

	err := r.db.WithContext(ctx).
		Where("updated_at > ?", yesterday).
		Limit(limit).
		Order("total_volume DESC, holder_count DESC").
		Find(&circles).Error
	return circles, err
}

// Count returns total number of circles
func (r *CircleRepository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&models.Circle{}).Count(&count).Error
	return count, err
}
