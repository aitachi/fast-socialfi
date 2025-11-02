/**
 * Author: Aitachi
 * Email: 44158892@qq.com
 * Date: 11-02-2025 17
 */

import { ethers } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

/**
 * Blockchain Configuration and Web3 Integration
 */
class BlockchainClient {
  private static instance: BlockchainClient;
  private provider: ethers.JsonRpcProvider;
  private chainId: number;

  private constructor() {
    const rpcUrl =
      process.env.BLOCKCHAIN_RPC_URL ||
      'https://eth-mainnet.g.alchemy.com/v2/demo';
    this.chainId = parseInt(process.env.BLOCKCHAIN_CHAIN_ID || '1');
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): BlockchainClient {
    if (!BlockchainClient.instance) {
      BlockchainClient.instance = new BlockchainClient();
    }
    return BlockchainClient.instance;
  }

  /**
   * Get provider
   */
  public getProvider(): ethers.JsonRpcProvider {
    return this.provider;
  }

  /**
   * Get chain ID
   */
  public getChainId(): number {
    return this.chainId;
  }

  /**
   * Verify wallet signature
   */
  public async verifySignature(
    message: string,
    signature: string,
    expectedAddress: string
  ): Promise<boolean> {
    try {
      const recoveredAddress = ethers.verifyMessage(message, signature);
      return (
        recoveredAddress.toLowerCase() === expectedAddress.toLowerCase()
      );
    } catch (error) {
      console.error('Failed to verify signature:', error);
      return false;
    }
  }

  /**
   * Get wallet balance (ETH)
   */
  public async getBalance(address: string): Promise<string> {
    try {
      const balance = await this.provider.getBalance(address);
      return ethers.formatEther(balance);
    } catch (error) {
      console.error('Failed to get balance:', error);
      throw error;
    }
  }

  /**
   * Get ERC20 token balance
   */
  public async getTokenBalance(
    walletAddress: string,
    tokenAddress: string
  ): Promise<string> {
    try {
      const abi = [
        'function balanceOf(address owner) view returns (uint256)',
        'function decimals() view returns (uint8)',
      ];
      const contract = new ethers.Contract(tokenAddress, abi, this.provider);
      const balance = await contract.balanceOf(walletAddress);
      const decimals = await contract.decimals();
      return ethers.formatUnits(balance, decimals);
    } catch (error) {
      console.error('Failed to get token balance:', error);
      throw error;
    }
  }

  /**
   * Get transaction details
   */
  public async getTransaction(txHash: string): Promise<any> {
    try {
      const tx = await this.provider.getTransaction(txHash);
      const receipt = await this.provider.getTransactionReceipt(txHash);
      return {
        transaction: tx,
        receipt,
      };
    } catch (error) {
      console.error('Failed to get transaction:', error);
      throw error;
    }
  }

  /**
   * Get current block number
   */
  public async getBlockNumber(): Promise<number> {
    try {
      return await this.provider.getBlockNumber();
    } catch (error) {
      console.error('Failed to get block number:', error);
      throw error;
    }
  }

  /**
   * Get NFT metadata from token URI
   */
  public async getNFTMetadata(
    contractAddress: string,
    tokenId: string
  ): Promise<any> {
    try {
      const abi = ['function tokenURI(uint256 tokenId) view returns (string)'];
      const contract = new ethers.Contract(
        contractAddress,
        abi,
        this.provider
      );
      const tokenURI = await contract.tokenURI(tokenId);

      // Fetch metadata from IPFS or HTTP
      if (tokenURI.startsWith('ipfs://')) {
        const ipfsHash = tokenURI.replace('ipfs://', '');
        const response = await fetch(`https://ipfs.io/ipfs/${ipfsHash}`);
        return await response.json();
      } else if (tokenURI.startsWith('http')) {
        const response = await fetch(tokenURI);
        return await response.json();
      }

      return null;
    } catch (error) {
      console.error('Failed to get NFT metadata:', error);
      throw error;
    }
  }

  /**
   * Validate Ethereum address
   */
  public isValidAddress(address: string): boolean {
    return ethers.isAddress(address);
  }

  /**
   * Test blockchain connection
   */
  public async testConnection(): Promise<boolean> {
    try {
      const blockNumber = await this.getBlockNumber();
      const network = await this.provider.getNetwork();
      console.log('Blockchain connection test successful:', {
        network: network.name,
        chainId: network.chainId,
        blockNumber,
      });
      return true;
    } catch (error) {
      console.error('Blockchain connection test failed:', error);
      return false;
    }
  }
}

export default BlockchainClient.getInstance();
