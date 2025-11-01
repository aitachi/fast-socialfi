package web3

// CircleFactoryABI is the ABI for CircleFactory contract
const CircleFactoryABI = `[
	{
		"inputs": [
			{"internalType": "address", "name": "_platformTreasury", "type": "address"}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{"internalType": "string", "name": "name", "type": "string"},
			{"internalType": "string", "name": "symbol", "type": "string"},
			{"internalType": "string", "name": "description", "type": "string"},
			{"internalType": "uint8", "name": "curveType", "type": "uint8"},
			{"internalType": "uint256", "name": "basePrice", "type": "uint256"},
			{"internalType": "uint256", "name": "k", "type": "uint256"},
			{"internalType": "uint256", "name": "m", "type": "uint256"},
			{"internalType": "uint256", "name": "n", "type": "uint256"}
		],
		"name": "createCircle",
		"outputs": [
			{"internalType": "uint256", "name": "circleId", "type": "uint256"}
		],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "uint256", "name": "", "type": "uint256"}
		],
		"name": "circles",
		"outputs": [
			{"internalType": "uint256", "name": "id", "type": "uint256"},
			{"internalType": "address", "name": "owner", "type": "address"},
			{"internalType": "address", "name": "tokenAddress", "type": "address"},
			{"internalType": "address", "name": "bondingCurve", "type": "address"},
			{"internalType": "string", "name": "name", "type": "string"},
			{"internalType": "string", "name": "symbol", "type": "string"},
			{"internalType": "string", "name": "description", "type": "string"},
			{"internalType": "bool", "name": "active", "type": "bool"},
			{"internalType": "uint8", "name": "curveType", "type": "uint8"},
			{"internalType": "uint256", "name": "createdAt", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "circleCount",
		"outputs": [
			{"internalType": "uint256", "name": "", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	}
]`

// BondingCurveABI is the ABI for BondingCurve contract
const BondingCurveABI = `[
	{
		"inputs": [
			{"internalType": "address", "name": "_factory", "type": "address"}
		],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "token", "type": "address"},
			{"internalType": "uint256", "name": "amount", "type": "uint256"},
			{"internalType": "uint256", "name": "maxCost", "type": "uint256"}
		],
		"name": "buyTokens",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "token", "type": "address"},
			{"internalType": "uint256", "name": "amount", "type": "uint256"},
			{"internalType": "uint256", "name": "minRefund", "type": "uint256"}
		],
		"name": "sellTokens",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "token", "type": "address"}
		],
		"name": "getCurrentPrice",
		"outputs": [
			{"internalType": "uint256", "name": "", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "token", "type": "address"},
			{"internalType": "uint256", "name": "amount", "type": "uint256"}
		],
		"name": "calculateBuyCost",
		"outputs": [
			{"internalType": "uint256", "name": "cost", "type": "uint256"},
			{"internalType": "uint256", "name": "fee", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "token", "type": "address"},
			{"internalType": "uint256", "name": "amount", "type": "uint256"}
		],
		"name": "calculateSellRefund",
		"outputs": [
			{"internalType": "uint256", "name": "refund", "type": "uint256"},
			{"internalType": "uint256", "name": "fee", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	}
]`

// CircleTokenABI is the ABI for CircleToken (ERC20)
const CircleTokenABI = `[
	{
		"inputs": [
			{"internalType": "address", "name": "account", "type": "address"}
		],
		"name": "balanceOf",
		"outputs": [
			{"internalType": "uint256", "name": "", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "totalSupply",
		"outputs": [
			{"internalType": "uint256", "name": "", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "name",
		"outputs": [
			{"internalType": "string", "name": "", "type": "string"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "symbol",
		"outputs": [
			{"internalType": "string", "name": "", "type": "string"}
		],
		"stateMutability": "view",
		"type": "function"
	}
]`
