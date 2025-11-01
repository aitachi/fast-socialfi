package web3

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Web3Service handles blockchain interactions
type Web3Service struct {
	client              *ethclient.Client
	chainID             *big.Int
	factoryAddress      common.Address
	bondingCurveAddress common.Address
	factoryABI          abi.ABI
	bondingCurveABI     abi.ABI
	tokenABI            abi.ABI
}

// NewWeb3Service creates a new Web3 service instance
func NewWeb3Service(rpcURL string, factoryAddr, bondingCurveAddr string) (*Web3Service, error) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to Ethereum client: %w", err)
	}

	chainID, err := client.ChainID(context.Background())
	if err != nil {
		return nil, fmt.Errorf("failed to get chain ID: %w", err)
	}

	// Parse ABIs
	factoryABI, err := abi.JSON(strings.NewReader(CircleFactoryABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse factory ABI: %w", err)
	}

	bondingCurveABI, err := abi.JSON(strings.NewReader(BondingCurveABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse bonding curve ABI: %w", err)
	}

	tokenABI, err := abi.JSON(strings.NewReader(CircleTokenABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse token ABI: %w", err)
	}

	return &Web3Service{
		client:              client,
		chainID:             chainID,
		factoryAddress:      common.HexToAddress(factoryAddr),
		bondingCurveAddress: common.HexToAddress(bondingCurveAddr),
		factoryABI:          factoryABI,
		bondingCurveABI:     bondingCurveABI,
		tokenABI:            tokenABI,
	}, nil
}

// CreateCircleParams represents parameters for creating a circle
type CreateCircleParams struct {
	Name        string
	Symbol      string
	Description string
	CurveType   uint8
	BasePrice   *big.Int
	K           *big.Int
	M           *big.Int
	N           *big.Int
}

// CreateCircle creates a new circle on-chain
func (s *Web3Service) CreateCircle(ctx context.Context, privateKey string, params CreateCircleParams) (string, error) {
	key, err := crypto.HexToECDSA(privateKey)
	if err != nil {
		return "", fmt.Errorf("invalid private key: %w", err)
	}

	auth, err := s.newTransactor(key)
	if err != nil {
		return "", err
	}

	// Pack the transaction data
	data, err := s.factoryABI.Pack(
		"createCircle",
		params.Name,
		params.Symbol,
		params.Description,
		params.CurveType,
		params.BasePrice,
		params.K,
		params.M,
		params.N,
	)
	if err != nil {
		return "", fmt.Errorf("failed to pack transaction: %w", err)
	}

	// Estimate gas
	gasLimit, err := s.client.EstimateGas(ctx, ethereum.CallMsg{
		From:  auth.From,
		To:    &s.factoryAddress,
		Value: auth.Value,
		Data:  data,
	})
	if err != nil {
		return "", fmt.Errorf("failed to estimate gas: %w", err)
	}

	auth.GasLimit = gasLimit + 50000 // Add buffer

	// Send transaction
	tx := types.NewTransaction(
		auth.Nonce.Uint64(),
		s.factoryAddress,
		auth.Value,
		auth.GasLimit,
		auth.GasPrice,
		data,
	)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(s.chainID), key)
	if err != nil {
		return "", fmt.Errorf("failed to sign transaction: %w", err)
	}

	err = s.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return "", fmt.Errorf("failed to send transaction: %w", err)
	}

	return signedTx.Hash().Hex(), nil
}

// GetCircle retrieves circle information
func (s *Web3Service) GetCircle(ctx context.Context, circleID *big.Int) (*CircleInfo, error) {
	data, err := s.factoryABI.Pack("circles", circleID)
	if err != nil {
		return nil, fmt.Errorf("failed to pack call: %w", err)
	}

	result, err := s.client.CallContract(ctx, ethereum.CallMsg{
		To:   &s.factoryAddress,
		Data: data,
	}, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call contract: %w", err)
	}

	var circle CircleInfo
	err = s.factoryABI.UnpackIntoInterface(&circle, "circles", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack result: %w", err)
	}

	return &circle, nil
}

// BuyTokens purchases circle tokens
func (s *Web3Service) BuyTokens(ctx context.Context, privateKey string, tokenAddress common.Address, amount *big.Int, maxCost *big.Int) (string, error) {
	key, err := crypto.HexToECDSA(privateKey)
	if err != nil {
		return "", fmt.Errorf("invalid private key: %w", err)
	}

	auth, err := s.newTransactor(key)
	if err != nil {
		return "", err
	}

	auth.Value = maxCost

	data, err := s.bondingCurveABI.Pack("buyTokens", tokenAddress, amount, maxCost)
	if err != nil {
		return "", fmt.Errorf("failed to pack transaction: %w", err)
	}

	gasLimit, err := s.client.EstimateGas(ctx, ethereum.CallMsg{
		From:  auth.From,
		To:    &s.bondingCurveAddress,
		Value: auth.Value,
		Data:  data,
	})
	if err != nil {
		return "", fmt.Errorf("failed to estimate gas: %w", err)
	}

	auth.GasLimit = gasLimit + 50000

	tx := types.NewTransaction(
		auth.Nonce.Uint64(),
		s.bondingCurveAddress,
		auth.Value,
		auth.GasLimit,
		auth.GasPrice,
		data,
	)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(s.chainID), key)
	if err != nil {
		return "", fmt.Errorf("failed to sign transaction: %w", err)
	}

	err = s.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return "", fmt.Errorf("failed to send transaction: %w", err)
	}

	return signedTx.Hash().Hex(), nil
}

// SellTokens sells circle tokens
func (s *Web3Service) SellTokens(ctx context.Context, privateKey string, tokenAddress common.Address, amount *big.Int, minRefund *big.Int) (string, error) {
	key, err := crypto.HexToECDSA(privateKey)
	if err != nil {
		return "", fmt.Errorf("invalid private key: %w", err)
	}

	auth, err := s.newTransactor(key)
	if err != nil {
		return "", err
	}

	data, err := s.bondingCurveABI.Pack("sellTokens", tokenAddress, amount, minRefund)
	if err != nil {
		return "", fmt.Errorf("failed to pack transaction: %w", err)
	}

	gasLimit, err := s.client.EstimateGas(ctx, ethereum.CallMsg{
		From: auth.From,
		To:   &s.bondingCurveAddress,
		Data: data,
	})
	if err != nil {
		return "", fmt.Errorf("failed to estimate gas: %w", err)
	}

	auth.GasLimit = gasLimit + 50000

	tx := types.NewTransaction(
		auth.Nonce.Uint64(),
		s.bondingCurveAddress,
		big.NewInt(0),
		auth.GasLimit,
		auth.GasPrice,
		data,
	)

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(s.chainID), key)
	if err != nil {
		return "", fmt.Errorf("failed to sign transaction: %w", err)
	}

	err = s.client.SendTransaction(ctx, signedTx)
	if err != nil {
		return "", fmt.Errorf("failed to send transaction: %w", err)
	}

	return signedTx.Hash().Hex(), nil
}

// GetTokenBalance retrieves token balance for an address
func (s *Web3Service) GetTokenBalance(ctx context.Context, tokenAddress, userAddress common.Address) (*big.Int, error) {
	data, err := s.tokenABI.Pack("balanceOf", userAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to pack call: %w", err)
	}

	result, err := s.client.CallContract(ctx, ethereum.CallMsg{
		To:   &tokenAddress,
		Data: data,
	}, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call contract: %w", err)
	}

	balance := new(big.Int)
	err = s.tokenABI.UnpackIntoInterface(&balance, "balanceOf", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack result: %w", err)
	}

	return balance, nil
}

// GetCurrentPrice retrieves current price for a token
func (s *Web3Service) GetCurrentPrice(ctx context.Context, tokenAddress common.Address) (*big.Int, error) {
	data, err := s.bondingCurveABI.Pack("getCurrentPrice", tokenAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to pack call: %w", err)
	}

	result, err := s.client.CallContract(ctx, ethereum.CallMsg{
		To:   &s.bondingCurveAddress,
		Data: data,
	}, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call contract: %w", err)
	}

	price := new(big.Int)
	err = s.bondingCurveABI.UnpackIntoInterface(&price, "getCurrentPrice", result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack result: %w", err)
	}

	return price, nil
}

// WaitForTransaction waits for a transaction to be mined
func (s *Web3Service) WaitForTransaction(ctx context.Context, txHash string) (*types.Receipt, error) {
	hash := common.HexToHash(txHash)

	receipt, err := bind.WaitMined(ctx, s.client, &types.Transaction{})
	if err != nil {
		return nil, fmt.Errorf("failed to wait for transaction: %w", err)
	}

	return receipt, nil
}

// Helper function to create a transactor
func (s *Web3Service) newTransactor(privateKey *ecdsa.PrivateKey) (*bind.TransactOpts, error) {
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		return nil, fmt.Errorf("error casting public key to ECDSA")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := s.client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		return nil, err
	}

	gasPrice, err := s.client.SuggestGasPrice(context.Background())
	if err != nil {
		return nil, err
	}

	auth := bind.NewKeyedTransactor(privateKey)
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0)
	auth.GasLimit = uint64(3000000)
	auth.GasPrice = gasPrice

	return auth, nil
}

// CircleInfo represents circle information from blockchain
type CircleInfo struct {
	ID             *big.Int
	Owner          common.Address
	TokenAddress   common.Address
	BondingCurve   common.Address
	Name           string
	Symbol         string
	Description    string
	Active         bool
	CurveType      uint8
	CreatedAt      *big.Int
}
