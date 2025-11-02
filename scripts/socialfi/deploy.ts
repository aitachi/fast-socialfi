import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

interface DeploymentAddresses {
  network: string;
  deployer: string;
  timestamp: string;
  SocialToken: string;
  SocialNFT: string;
  ContentRegistry: string;
  Staking: string;
  Governance: string;
}

interface TransactionHashes {
  network: string;
  timestamp: string;
  deployments: {
    SocialToken: string;
    SocialNFT: string;
    ContentRegistry: string;
    Staking: string;
    Governance: string;
  };
  configurations: {
    [key: string]: string;
  };
}

async function main() {
  console.log("====================================");
  console.log("  Fast SocialFi - Contract Deployment");
  console.log("====================================\n");

  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  console.log(`Deploying contracts to ${network.name} (Chain ID: ${network.chainId})`);
  console.log(`Deployer address: ${deployer.address}`);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`Deployer balance: ${ethers.formatEther(balance)} ETH\n`);

  // Initialize deployment records
  const deploymentAddresses: DeploymentAddresses = {
    network: network.name,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    SocialToken: "",
    SocialNFT: "",
    ContentRegistry: "",
    Staking: "",
    Governance: "",
  };

  const transactionHashes: TransactionHashes = {
    network: network.name,
    timestamp: new Date().toISOString(),
    deployments: {
      SocialToken: "",
      SocialNFT: "",
      ContentRegistry: "",
      Staking: "",
      Governance: "",
    },
    configurations: {},
  };

  // ========== Step 1: Deploy SocialToken ==========
  console.log("📝 [1/5] Deploying SocialToken...");
  const SocialToken = await ethers.getContractFactory("SocialToken");
  const socialToken = await SocialToken.deploy(deployer.address);
  await socialToken.waitForDeployment();

  const socialTokenAddress = await socialToken.getAddress();
  const socialTokenTx = socialToken.deploymentTransaction();

  deploymentAddresses.SocialToken = socialTokenAddress;
  if (socialTokenTx) {
    transactionHashes.deployments.SocialToken = socialTokenTx.hash;
  }

  console.log(`✅ SocialToken deployed to: ${socialTokenAddress}`);
  console.log(`   Transaction hash: ${socialTokenTx?.hash}\n`);

  // ========== Step 2: Deploy SocialNFT ==========
  console.log("📝 [2/5] Deploying SocialNFT...");
  const mintingFee = ethers.parseEther("0.001"); // 0.001 ETH minting fee

  const SocialNFT = await ethers.getContractFactory("SocialNFT");
  const socialNFT = await SocialNFT.deploy(deployer.address, mintingFee);
  await socialNFT.waitForDeployment();

  const socialNFTAddress = await socialNFT.getAddress();
  const socialNFTTx = socialNFT.deploymentTransaction();

  deploymentAddresses.SocialNFT = socialNFTAddress;
  if (socialNFTTx) {
    transactionHashes.deployments.SocialNFT = socialNFTTx.hash;
  }

  console.log(`✅ SocialNFT deployed to: ${socialNFTAddress}`);
  console.log(`   Minting Fee: ${ethers.formatEther(mintingFee)} ETH`);
  console.log(`   Transaction hash: ${socialNFTTx?.hash}\n`);

  // ========== Step 3: Deploy ContentRegistry ==========
  console.log("📝 [3/5] Deploying ContentRegistry...");
  const ContentRegistry = await ethers.getContractFactory("ContentRegistry");
  const contentRegistry = await ContentRegistry.deploy(
    deployer.address,
    socialTokenAddress
  );
  await contentRegistry.waitForDeployment();

  const contentRegistryAddress = await contentRegistry.getAddress();
  const contentRegistryTx = contentRegistry.deploymentTransaction();

  deploymentAddresses.ContentRegistry = contentRegistryAddress;
  if (contentRegistryTx) {
    transactionHashes.deployments.ContentRegistry = contentRegistryTx.hash;
  }

  console.log(`✅ ContentRegistry deployed to: ${contentRegistryAddress}`);
  console.log(`   Transaction hash: ${contentRegistryTx?.hash}\n`);

  // ========== Step 4: Deploy Staking ==========
  console.log("📝 [4/5] Deploying Staking...");
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(deployer.address, socialTokenAddress);
  await staking.waitForDeployment();

  const stakingAddress = await staking.getAddress();
  const stakingTx = staking.deploymentTransaction();

  deploymentAddresses.Staking = stakingAddress;
  if (stakingTx) {
    transactionHashes.deployments.Staking = stakingTx.hash;
  }

  console.log(`✅ Staking deployed to: ${stakingAddress}`);
  console.log(`   Transaction hash: ${stakingTx?.hash}\n`);

  // ========== Step 5: Deploy Governance ==========
  console.log("📝 [5/5] Deploying Governance...");
  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(deployer.address, socialTokenAddress);
  await governance.waitForDeployment();

  const governanceAddress = await governance.getAddress();
  const governanceTx = governance.deploymentTransaction();

  deploymentAddresses.Governance = governanceAddress;
  if (governanceTx) {
    transactionHashes.deployments.Governance = governanceTx.hash;
  }

  console.log(`✅ Governance deployed to: ${governanceAddress}`);
  console.log(`   Transaction hash: ${governanceTx?.hash}\n`);

  // ========== Configuration ==========
  console.log("⚙️  Configuring contracts...\n");

  // Fund staking reward pool (10% of total supply)
  console.log("💰 Funding Staking reward pool...");
  const rewardAmount = ethers.parseEther("100000000"); // 100M tokens (10%)
  const approveTx = await socialToken.approve(stakingAddress, rewardAmount);
  await approveTx.wait();
  transactionHashes.configurations.stakingApproval = approveTx.hash;

  const fundTx = await staking.fundRewardPool(rewardAmount);
  await fundTx.wait();
  transactionHashes.configurations.stakingFund = fundTx.hash;
  console.log(`✅ Staking pool funded with ${ethers.formatEther(rewardAmount)} tokens`);
  console.log(`   Transaction hash: ${fundTx.hash}\n`);

  // Fund governance treasury (5% of total supply)
  console.log("💰 Funding Governance treasury...");
  const treasuryAmount = ethers.parseEther("50000000"); // 50M tokens (5%)
  const govApproveTx = await socialToken.approve(governanceAddress, treasuryAmount);
  await govApproveTx.wait();
  transactionHashes.configurations.governanceApproval = govApproveTx.hash;

  const treasuryTx = await governance.fundTreasury(treasuryAmount);
  await treasuryTx.wait();
  transactionHashes.configurations.governanceFund = treasuryTx.hash;
  console.log(`✅ Governance treasury funded with ${ethers.formatEther(treasuryAmount)} tokens`);
  console.log(`   Transaction hash: ${treasuryTx.hash}\n`);

  // ========== Save Deployment Info ==========
  const outputDir = path.join(process.cwd(), "deployments");
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  // Save addresses
  const addressesFile = path.join(outputDir, "DEPLOYMENT_ADDRESSES.json");
  fs.writeFileSync(addressesFile, JSON.stringify(deploymentAddresses, null, 2));
  console.log(`📄 Deployment addresses saved to: ${addressesFile}`);

  // Save transaction hashes
  const hashesFile = path.join(outputDir, "TRANSACTION_HASHES.json");
  fs.writeFileSync(hashesFile, JSON.stringify(transactionHashes, null, 2));
  console.log(`📄 Transaction hashes saved to: ${hashesFile}`);

  // ========== Summary ==========
  console.log("\n====================================");
  console.log("  Deployment Summary");
  console.log("====================================");
  console.log(`Network: ${network.name} (Chain ID: ${network.chainId})`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`\nContract Addresses:`);
  console.log(`  SocialToken:      ${socialTokenAddress}`);
  console.log(`  SocialNFT:        ${socialNFTAddress}`);
  console.log(`  ContentRegistry:  ${contentRegistryAddress}`);
  console.log(`  Staking:          ${stakingAddress}`);
  console.log(`  Governance:       ${governanceAddress}`);
  console.log("\n====================================");
  console.log("✅ Deployment Complete!");
  console.log("====================================\n");

  console.log("Next steps:");
  console.log("1. Verify contracts on Etherscan: npm run verify:sepolia");
  console.log("2. Test contract functions");
  console.log("3. Update frontend with new addresses\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
