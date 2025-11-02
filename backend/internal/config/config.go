// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

type Config struct {
	App        AppConfig
	Database   DatabaseConfig
	Redis      RedisConfig
	Blockchain BlockchainConfig
	IPFS       IPFSConfig
	Security   SecurityConfig
	JWT        JWTConfig
}

type AppConfig struct {
	Environment string
	Host        string
	Port        string
	LogLevel    string
}

type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Database string
	MaxConns int
	MaxIdle  int
}

type RedisConfig struct {
	Enabled  bool
	Host     string
	Port     string
	Password string
	DB       int
}

type BlockchainConfig struct {
	NetworkName       string
	RPCEndpoint       string
	WSEndpoint        string
	PrivateKey        string
	ChainID           int64
	FactoryAddress    string
	BondingCurveAddress string
	GasLimit          uint64
	GasPrice          int64
}

type IPFSConfig struct {
	NodeURL string
	Gateway string
}

type SecurityConfig struct {
	RateLimit        int
	RateLimitWindow  time.Duration
	MaxRequestSize   int64
	AllowedOrigins   []string
}

type JWTConfig struct {
	Secret     string
	Expiration time.Duration
}

func Load() (*Config, error) {
	cfg := &Config{
		App: AppConfig{
			Environment: getEnv("NODE_ENV", "development"),
			Host:        getEnv("API_HOST", "0.0.0.0"),
			Port:        getEnv("API_PORT", "8080"),
			LogLevel:    getEnv("LOG_LEVEL", "debug"),
		},
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "3306"),
			User:     getEnv("DB_USER", "root"),
			Password: getEnv("DB_PASSWORD", ""),
			Database: getEnv("DB_NAME", "socialfi_db"),
			MaxConns: getEnvInt("DB_MAX_CONNS", 25),
			MaxIdle:  getEnvInt("DB_MAX_IDLE", 5),
		},
		Redis: RedisConfig{
			Enabled:  getEnvBool("REDIS_ENABLED", false),
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvInt("REDIS_DB", 0),
		},
		Blockchain: BlockchainConfig{
			NetworkName:    getEnv("NETWORK", "sepolia"),
			RPCEndpoint:    getEnv("SEPOLIA_RPC_URL", ""),
			WSEndpoint:     getEnv("WS_RPC_URL", ""),
			PrivateKey:     getEnv("PRIVATE_KEY", ""),
			ChainID:        getEnvInt64("CHAIN_ID", 11155111),
			FactoryAddress: getEnv("FACTORY_ADDRESS", ""),
			BondingCurveAddress: getEnv("BONDING_CURVE_ADDRESS", ""),
			GasLimit:       uint64(getEnvInt("GAS_LIMIT", 3000000)),
			GasPrice:       getEnvInt64("GAS_PRICE", 0),
		},
		IPFS: IPFSConfig{
			NodeURL: getEnv("IPFS_NODE_URL", "https://ipfs.infura.io:5001"),
			Gateway: getEnv("IPFS_GATEWAY", "https://ipfs.io/ipfs/"),
		},
		Security: SecurityConfig{
			RateLimit:       getEnvInt("RATE_LIMIT_REQUESTS", 100),
			RateLimitWindow: time.Duration(getEnvInt("RATE_LIMIT_WINDOW", 60)) * time.Second,
			MaxRequestSize:  getEnvInt64("MAX_REQUEST_SIZE", 10<<20), // 10MB
			AllowedOrigins:  []string{getEnv("CORS_ORIGINS", "*")},
		},
		JWT: JWTConfig{
			Secret:     getEnv("JWT_SECRET", "your-secret-key-here"),
			Expiration: time.Duration(getEnvInt("JWT_EXPIRATION_HOURS", 24)) * time.Hour,
		},
	}

	// Validate required fields
	if cfg.Blockchain.RPCEndpoint == "" {
		return nil, fmt.Errorf("SEPOLIA_RPC_URL is required")
	}

	return cfg, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvInt64(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.ParseInt(value, 10, 64); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}
