import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

interface DeploymentAddresses {
  SocialToken: string;
  SocialNFT: string;
  ContentRegistry: string;
  Staking: string;
  Governance: string;
}

interface TestTransactions {
  network: string;
  timestamp: string;
  tests: {
    [key: string]: {
      description: string;
      txHash: string;
      success: boolean;
      error?: string;
    };
  };
}

async function main() {
  console.log("====================================");
  console.log("  Fast SocialFi - On-Chain Testing");
  console.log("====================================\n");

  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  console.log(`Network: ${network.name} (Chain ID: ${network.chainId})`);
  console.log(`Tester address: ${deployer.address}\n`);

  // Load deployment addresses
  const addressesFile = path.join(process.cwd(), "deployments", "DEPLOYMENT_ADDRESSES.json");
  if (!fs.existsSync(addressesFile)) {
    throw new Error(`Deployment addresses file not found`);
  }

  const addresses: DeploymentAddresses = JSON.parse(fs.readFileSync(addressesFile, "utf8"));

  // Initialize test transaction record
  const testTxs: TestTransactions = {
    network: network.name,
    timestamp: new Date().toISOString(),
    tests: {},
  };

  // Get contract instances
  const socialToken = await ethers.getContractAt("SocialToken", addresses.SocialToken);
  const socialNFT = await ethers.getContractAt("SocialNFT", addresses.SocialNFT);
  const contentRegistry = await ethers.getContractAt("ContentRegistry", addresses.ContentRegistry);
  const staking = await ethers.getContractAt("Staking", addresses.Staking);
  const governance = await ethers.getContractAt("Governance", addresses.Governance);

  console.log("📝 Loaded contract instances\n");

  // ========== Test 1: Token Transfer ==========
  console.log("🧪 Test 1: Token Transfer");
  try {
    const transferAmount = ethers.parseEther("1000");
    const tx1 = await socialToken.transfer(deployer.address, transferAmount);
    await tx1.wait();
    const balance = await socialToken.balanceOf(deployer.address);
    testTxs.tests.tokenTransfer = {
      description: `Transfer ${ethers.formatEther(transferAmount)} SOCIAL tokens`,
      txHash: tx1.hash,
      success: true,
    };
    console.log(`✅ Transferred tokens. Balance: ${ethers.formatEther(balance)} SOCIAL`);
    console.log(`   Tx: ${tx1.hash}\n`);
  } catch (error: any) {
    testTxs.tests.tokenTransfer = {
      description: "Transfer SOCIAL tokens",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Test 2: Mint NFT ==========
  console.log("🧪 Test 2: Mint NFT");
  try {
    const mintingFee = ethers.parseEther("0.001");
    const ipfsUri = "ipfs://QmTest123456789";
    const tx2 = await socialNFT.mint(ipfsUri, "image", { value: mintingFee });
    const receipt = await tx2.wait();
    testTxs.tests.nftMint = {
      description: "Mint NFT with IPFS URI",
      txHash: tx2.hash,
      success: true,
    };
    console.log(`✅ NFT minted successfully`);
    console.log(`   Tx: ${tx2.hash}\n`);
  } catch (error: any) {
    testTxs.tests.nftMint = {
      description: "Mint NFT with IPFS URI",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Test 3: Register Content ==========
  console.log("🧪 Test 3: Register Content");
  try {
    const ipfsHash = "QmContentTest123456789";
    const tx3 = await contentRegistry.registerContent(
      ipfsHash,
      false,
      0,
      "CC-BY-4.0",
      0
    );
    await tx3.wait();
    testTxs.tests.contentRegister = {
      description: "Register content with IPFS hash",
      txHash: tx3.hash,
      success: true,
    };
    console.log(`✅ Content registered`);
    console.log(`   Tx: ${tx3.hash}\n`);
  } catch (error: any) {
    testTxs.tests.contentRegister = {
      description: "Register content with IPFS hash",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Test 4: Tip Content with ETH ==========
  console.log("🧪 Test 4: Tip Content with ETH");
  try {
    const tipAmount = ethers.parseEther("0.01");
    const tx4 = await contentRegistry.tipContentETH(1, { value: tipAmount });
    await tx4.wait();
    testTxs.tests.contentTipETH = {
      description: `Tip content with ${ethers.formatEther(tipAmount)} ETH`,
      txHash: tx4.hash,
      success: true,
    };
    console.log(`✅ Content tipped with ETH`);
    console.log(`   Tx: ${tx4.hash}\n`);
  } catch (error: any) {
    testTxs.tests.contentTipETH = {
      description: "Tip content with ETH",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Test 5: Stake Tokens ==========
  console.log("🧪 Test 5: Stake Tokens");
  try {
    const stakeAmount = ethers.parseEther("100");
    const lockPeriod = 7 * 24 * 60 * 60; // 7 days

    // Approve staking contract
    const approveTx = await socialToken.approve(addresses.Staking, stakeAmount);
    await approveTx.wait();

    const tx5 = await staking.stake(stakeAmount, lockPeriod, false);
    await tx5.wait();
    testTxs.tests.tokenStake = {
      description: `Stake ${ethers.formatEther(stakeAmount)} SOCIAL for 7 days`,
      txHash: tx5.hash,
      success: true,
    };
    console.log(`✅ Tokens staked`);
    console.log(`   Tx: ${tx5.hash}\n`);
  } catch (error: any) {
    testTxs.tests.tokenStake = {
      description: "Stake SOCIAL tokens",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Test 6: Create Governance Proposal ==========
  console.log("🧪 Test 6: Create Governance Proposal");
  try {
    const description = "Test Proposal: Update platform fee to 2%";
    const proposalType = 0; // ParameterChange
    const callData = ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "uint256", "string"],
      [deployer.address, ethers.parseEther("1000"), "Test treasury spend"]
    );

    const tx6 = await governance.propose(
      description,
      proposalType,
      ethers.ZeroAddress,
      callData
    );
    await tx6.wait();
    testTxs.tests.governanceProposal = {
      description: "Create governance proposal",
      txHash: tx6.hash,
      success: true,
    };
    console.log(`✅ Governance proposal created`);
    console.log(`   Tx: ${tx6.hash}\n`);
  } catch (error: any) {
    testTxs.tests.governanceProposal = {
      description: "Create governance proposal",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Test 7: Vote on Proposal ==========
  console.log("🧪 Test 7: Vote on Proposal");
  try {
    const proposalId = 1;
    const support = 1; // Vote for

    const tx7 = await governance.castVote(proposalId, support);
    await tx7.wait();
    testTxs.tests.governanceVote = {
      description: "Vote on governance proposal",
      txHash: tx7.hash,
      success: true,
    };
    console.log(`✅ Vote cast on proposal`);
    console.log(`   Tx: ${tx7.hash}\n`);
  } catch (error: any) {
    testTxs.tests.governanceVote = {
      description: "Vote on governance proposal",
      txHash: "",
      success: false,
      error: error.message,
    };
    console.error(`❌ Failed: ${error.message}\n`);
  }

  // ========== Save Test Results ==========
  const outputDir = path.join(process.cwd(), "deployments");
  const testFile = path.join(outputDir, "TEST_TRANSACTIONS.json");
  fs.writeFileSync(testFile, JSON.stringify(testTxs, null, 2));
  console.log(`📄 Test transactions saved to: ${testFile}\n`);

  // ========== Summary ==========
  console.log("====================================");
  console.log("  Test Summary");
  console.log("====================================");

  let successCount = 0;
  let failureCount = 0;

  for (const [testName, result] of Object.entries(testTxs.tests)) {
    const status = result.success ? "✅ PASS" : "❌ FAIL";
    console.log(`${status} - ${result.description}`);
    if (result.success) {
      successCount++;
      console.log(`       Tx: ${result.txHash}`);
    } else {
      failureCount++;
      console.log(`       Error: ${result.error}`);
    }
  }

  console.log("\n====================================");
  console.log(`✅ Passed: ${successCount}`);
  console.log(`❌ Failed: ${failureCount}`);
  console.log(`Total: ${successCount + failureCount}`);
  console.log("====================================\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
