// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package models

import (
	"time"
)

// User represents a platform user
type User struct {
	UserID              uint64    `json:"user_id" gorm:"primaryKey;autoIncrement"`
	WalletAddress       string    `json:"wallet_address" gorm:"uniqueIndex;not null;size:42"`
	ENSName             *string   `json:"ens_name" gorm:"size:255"`
	Username            *string   `json:"username" gorm:"uniqueIndex;size:50"`
	DisplayName         *string   `json:"display_name" gorm:"size:100"`
	Bio                 *string   `json:"bio" gorm:"type:text"`
	AvatarIPFSHash      *string   `json:"avatar_ipfs_hash" gorm:"size:66"`
	CoverIPFSHash       *string   `json:"cover_ipfs_hash" gorm:"size:66"`
	Email               *string   `json:"email" gorm:"size:255"`
	TwitterHandle       *string   `json:"twitter_handle" gorm:"size:50"`
	GithubHandle        *string   `json:"github_handle" gorm:"size:50"`
	FollowerCount       uint      `json:"follower_count" gorm:"default:0"`
	FollowingCount      uint      `json:"following_count" gorm:"default:0"`
	CircleCount         uint      `json:"circle_count" gorm:"default:0"`
	ReputationScore     float64   `json:"reputation_score" gorm:"default:0"`
	TotalTradingVolume  string    `json:"total_trading_volume" gorm:"type:decimal(30,18);default:0"`
	TotalContentCount   uint      `json:"total_content_count" gorm:"default:0"`
	TotalRewardReceived string    `json:"total_reward_received" gorm:"type:decimal(30,18);default:0"`
	NFTCount            uint      `json:"nft_count" gorm:"default:0"`
	TokenPortfolioValue string    `json:"token_portfolio_value" gorm:"type:decimal(30,18);default:0"`
	NotificationEnabled bool      `json:"notification_enabled" gorm:"default:true"`
	EmailVerified       bool      `json:"email_verified" gorm:"default:false"`
	KYCVerified         bool      `json:"kyc_verified" gorm:"default:false"`
	IsBanned            bool      `json:"is_banned" gorm:"default:false"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
	LastActiveAt        *time.Time `json:"last_active_at"`
}

// TableName specifies the table name for User model
func (User) TableName() string {
	return "users"
}

// UserRelationship represents relationships between users
type UserRelationship struct {
	RelationshipID   uint64    `json:"relationship_id" gorm:"primaryKey;autoIncrement"`
	FromUserID       uint64    `json:"from_user_id" gorm:"not null;index:idx_from_type"`
	RelationshipType string    `json:"relationship_type" gorm:"type:enum('FOLLOWS','BLOCKS','COLLABORATES');not null"`
	ToUserID         uint64    `json:"to_user_id" gorm:"not null;index:idx_to_type"`
	StrengthScore    float64   `json:"strength_score" gorm:"default:1.0"`
	InteractionCount uint      `json:"interaction_count" gorm:"default:0"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

func (UserRelationship) TableName() string {
	return "user_relationships"
}

// Circle represents a social circle
type Circle struct {
	ID                  uint64    `json:"id" gorm:"primaryKey;autoIncrement"`
	ChainCircleID       uint64    `json:"chain_circle_id" gorm:"uniqueIndex"`
	OwnerAddress        string    `json:"owner_address" gorm:"size:42;index"`
	TokenAddress        string    `json:"token_address" gorm:"size:42;uniqueIndex"`
	BondingCurveAddress string    `json:"bonding_curve_address" gorm:"size:42"`
	Name                string    `json:"name" gorm:"not null;size:100"`
	Symbol              string    `json:"symbol" gorm:"not null;size:20"`
	Description         string    `json:"description" gorm:"type:text"`
	CurveType           uint8     `json:"curve_type" gorm:"default:0"`
	Category            *string   `json:"category" gorm:"size:50;index"`
	TotalSupply         string    `json:"total_supply" gorm:"type:decimal(30,18);default:0"`
	HolderCount         int       `json:"holder_count" gorm:"default:0"`
	TransactionCount    int       `json:"transaction_count" gorm:"default:0"`
	TotalVolume         string    `json:"total_volume" gorm:"type:decimal(30,18);default:0"`
	Active              bool      `json:"active" gorm:"default:true"`
	Status              string    `json:"status" gorm:"default:'pending'"`
	TxHash              string    `json:"tx_hash" gorm:"size:66"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
}

func (Circle) TableName() string {
	return "circles"
}

// UserCircleRelationship represents user membership in circles
type UserCircleRelationship struct {
	UCRelationshipID   uint64     `json:"uc_relationship_id" gorm:"primaryKey;autoIncrement"`
	UserID             uint64     `json:"user_id" gorm:"not null;index"`
	CircleID           uint64     `json:"circle_id" gorm:"not null;index"`
	RelationshipType   string     `json:"relationship_type" gorm:"type:enum('OWNS','MODERATOR','MEMBER');not null"`
	TokenBalance       string     `json:"token_balance" gorm:"type:decimal(30,18);default:0"`
	JoinPrice          *string    `json:"join_price" gorm:"type:decimal(30,18)"`
	ContributionScore  float64    `json:"contribution_score" gorm:"default:0"`
	CanPost            bool       `json:"can_post" gorm:"default:true"`
	CanModerate        bool       `json:"can_moderate" gorm:"default:false"`
	CanInvite          bool       `json:"can_invite" gorm:"default:false"`
	JoinedAt           time.Time  `json:"joined_at"`
	LastInteractionAt  *time.Time `json:"last_interaction_at"`

	User   User   `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Circle Circle `json:"circle,omitempty" gorm:"foreignKey:CircleID"`
}

func (UserCircleRelationship) TableName() string {
	return "user_circle_relationships"
}

// Post represents a content post
type Post struct {
	PostID            uint64     `json:"post_id" gorm:"primaryKey;autoIncrement"`
	AuthorID          uint64     `json:"author_id" gorm:"not null;index"`
	CircleID          *uint64    `json:"circle_id" gorm:"index"`
	ContentIPFSHash   string     `json:"content_ipfs_hash" gorm:"not null;size:66"`
	ContentType       string     `json:"content_type" gorm:"type:enum('TEXT','IMAGE','VIDEO','LINK','NFT');not null"`
	Title             *string    `json:"title" gorm:"size:255"`
	PreviewText       *string    `json:"preview_text" gorm:"type:text"`
	TxHash            *string    `json:"tx_hash" gorm:"size:66"`
	BlockNumber       *uint64    `json:"block_number"`
	Upvotes           uint       `json:"upvotes" gorm:"default:0"`
	Downvotes         uint       `json:"downvotes" gorm:"default:0"`
	CommentCount      uint       `json:"comment_count" gorm:"default:0"`
	RewardAmount      string     `json:"reward_amount" gorm:"type:decimal(30,18);default:0"`
	IsNFT             bool       `json:"is_nft" gorm:"default:false"`
	NFTTokenID        *uint64    `json:"nft_token_id"`
	NFTContractAddress *string   `json:"nft_contract_address" gorm:"size:42"`
	IsDeleted         bool       `json:"is_deleted" gorm:"default:false"`
	IsPinned          bool       `json:"is_pinned" gorm:"default:false"`
	ModerationStatus  string     `json:"moderation_status" gorm:"type:enum('PENDING','APPROVED','REJECTED','FLAGGED');default:'APPROVED'"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`

	Author User    `json:"author,omitempty" gorm:"foreignKey:AuthorID"`
	Circle *Circle `json:"circle,omitempty" gorm:"foreignKey:CircleID"`
}

func (Post) TableName() string {
	return "posts"
}

// Comment represents a comment on a post
type Comment struct {
	CommentID       uint64    `json:"comment_id" gorm:"primaryKey;autoIncrement"`
	PostID          uint64    `json:"post_id" gorm:"not null;index"`
	AuthorID        uint64    `json:"author_id" gorm:"not null;index"`
	ParentCommentID *uint64   `json:"parent_comment_id" gorm:"index"`
	Content         string    `json:"content" gorm:"type:text;not null"`
	Upvotes         uint      `json:"upvotes" gorm:"default:0"`
	IsDeleted       bool      `json:"is_deleted" gorm:"default:false"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`

	Author User  `json:"author,omitempty" gorm:"foreignKey:AuthorID"`
	Post   Post  `json:"post,omitempty" gorm:"foreignKey:PostID"`
}

func (Comment) TableName() string {
	return "comments"
}

// Trade represents a token trade
type Trade struct {
	TradeID     uint64    `json:"trade_id" gorm:"primaryKey;autoIncrement"`
	TxHash      string    `json:"tx_hash" gorm:"uniqueIndex;not null;size:66"`
	TraderID    uint64    `json:"trader_id" gorm:"not null;index:idx_trader_time"`
	CircleID    uint64    `json:"circle_id" gorm:"not null;index:idx_circle_time"`
	TradeType   string    `json:"trade_type" gorm:"type:enum('BUY','SELL');not null"`
	TokenAmount string    `json:"token_amount" gorm:"type:decimal(30,18);not null"`
	ETHAmount   string    `json:"eth_amount" gorm:"type:decimal(30,18);not null"`
	Price       string    `json:"price" gorm:"type:decimal(30,18);not null"`
	Fee         string    `json:"fee" gorm:"type:decimal(30,18);default:0"`
	BlockNumber uint64    `json:"block_number" gorm:"not null"`
	Timestamp   time.Time `json:"timestamp" gorm:"not null;index"`

	Trader User   `json:"trader,omitempty" gorm:"foreignKey:TraderID"`
	Circle Circle `json:"circle,omitempty" gorm:"foreignKey:CircleID"`
}

func (Trade) TableName() string {
	return "trades"
}

// Notification represents a user notification
type Notification struct {
	NotificationID  uint64    `json:"notification_id" gorm:"primaryKey;autoIncrement"`
	UserID          uint64    `json:"user_id" gorm:"not null;index:idx_user_read"`
	NotificationType string   `json:"notification_type" gorm:"type:enum('NEW_FOLLOWER','NEW_COMMENT','POST_REWARD','CIRCLE_INVITE','TRADE_EXECUTED','GOVERNANCE_PROPOSAL','MENTION');not null"`
	Title           string    `json:"title" gorm:"not null;size:255"`
	Content         *string   `json:"content" gorm:"type:text"`
	RelatedUserID   *uint64   `json:"related_user_id"`
	RelatedPostID   *uint64   `json:"related_post_id"`
	RelatedCircleID *uint64   `json:"related_circle_id"`
	IsRead          bool      `json:"is_read" gorm:"default:false;index:idx_user_read"`
	CreatedAt       time.Time `json:"created_at"`
}

func (Notification) TableName() string {
	return "notifications"
}

// DirectMessage represents an encrypted direct message
type DirectMessage struct {
	MessageID         uint64    `json:"message_id" gorm:"primaryKey;autoIncrement"`
	FromUserID        uint64    `json:"from_user_id" gorm:"not null;index"`
	ToUserID          uint64    `json:"to_user_id" gorm:"not null;index"`
	EncryptedContent  string    `json:"encrypted_content" gorm:"type:text;not null"`
	EncryptionKeyHash *string   `json:"encryption_key_hash" gorm:"size:66"`
	IsRead            bool      `json:"is_read" gorm:"default:false"`
	CreatedAt         time.Time `json:"created_at"`

	FromUser User `json:"from_user,omitempty" gorm:"foreignKey:FromUserID"`
	ToUser   User `json:"to_user,omitempty" gorm:"foreignKey:ToUserID"`
}

func (DirectMessage) TableName() string {
	return "direct_messages"
}

// Transaction represents a blockchain transaction
type Transaction struct {
	ID           uint64    `json:"id" gorm:"primaryKey;autoIncrement"`
	CircleID     uint64    `json:"circle_id" gorm:"index"`
	TxHash       string    `json:"tx_hash" gorm:"uniqueIndex;not null;size:66"`
	TxType       string    `json:"tx_type" gorm:"not null"`
	FromAddress  string    `json:"from_address" gorm:"size:42;index"`
	ToAddress    string    `json:"to_address" gorm:"size:42;index"`
	Amount       string    `json:"amount" gorm:"type:decimal(30,18)"`
	Status       string    `json:"status" gorm:"default:'pending'"`
	TokenAddress string    `json:"token_address" gorm:"size:42"`
	Timestamp    time.Time `json:"timestamp"`
	CreatedAt    time.Time `json:"created_at"`
}

func (Transaction) TableName() string {
	return "transactions"
}

// CircleStats represents circle statistics
type CircleStats struct {
	TotalSupply      string
	HolderCount      int
	TransactionCount int
	TotalVolume      string
}

// VolumeStats represents volume statistics
type VolumeStats struct {
	TotalVolume      string
	TransactionCount int
}

// CircleDetail represents detailed circle information
type CircleDetail struct {
	*Circle
	CurrentPrice interface{} `json:"current_price"`
}
