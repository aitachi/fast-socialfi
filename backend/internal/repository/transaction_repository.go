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

// TransactionRepository handles transaction data access
type TransactionRepository struct {
	db *gorm.DB
}

// NewTransactionRepository creates a new transaction repository
func NewTransactionRepository(db *gorm.DB) *TransactionRepository {
	return &TransactionRepository{db: db}
}

// Create creates a new transaction record
func (r *TransactionRepository) Create(ctx context.Context, tx *models.Transaction) error {
	return r.db.WithContext(ctx).Create(tx).Error
}

// GetByHash retrieves a transaction by hash
func (r *TransactionRepository) GetByHash(ctx context.Context, txHash string) (*models.Transaction, error) {
	var tx models.Transaction
	err := r.db.WithContext(ctx).Where("tx_hash = ?", txHash).First(&tx).Error
	if err != nil {
		return nil, err
	}
	return &tx, nil
}

// GetByUser retrieves transactions for a user
func (r *TransactionRepository) GetByUser(ctx context.Context, userAddress string, limit, offset int) ([]*models.Transaction, error) {
	var txs []*models.Transaction
	err := r.db.WithContext(ctx).
		Where("from_address = ? OR to_address = ?", userAddress, userAddress).
		Limit(limit).
		Offset(offset).
		Order("timestamp DESC").
		Find(&txs).Error
	return txs, err
}

// GetByCircle retrieves transactions for a circle
func (r *TransactionRepository) GetByCircle(ctx context.Context, circleID uint64, limit, offset int) ([]*models.Transaction, error) {
	var txs []*models.Transaction
	err := r.db.WithContext(ctx).
		Where("circle_id = ?", circleID).
		Limit(limit).
		Offset(offset).
		Order("timestamp DESC").
		Find(&txs).Error
	return txs, err
}

// Update updates transaction status
func (r *TransactionRepository) Update(ctx context.Context, tx *models.Transaction) error {
	return r.db.WithContext(ctx).Save(tx).Error
}

// GetPendingTransactions retrieves pending transactions
func (r *TransactionRepository) GetPendingTransactions(ctx context.Context) ([]*models.Transaction, error) {
	var txs []*models.Transaction
	err := r.db.WithContext(ctx).
		Where("status = ?", "pending").
		Order("timestamp ASC").
		Find(&txs).Error
	return txs, err
}

// GetVolumeStats retrieves volume statistics for a circle
func (r *TransactionRepository) GetVolumeStats(ctx context.Context, circleID uint64, since time.Time) (*models.VolumeStats, error) {
	var stats models.VolumeStats

	err := r.db.WithContext(ctx).Model(&models.Transaction{}).
		Select("SUM(amount) as total_volume, COUNT(*) as transaction_count").
		Where("circle_id = ? AND timestamp > ? AND status = ?", circleID, since, "confirmed").
		Scan(&stats).Error

	if err != nil {
		return nil, err
	}

	return &stats, nil
}
