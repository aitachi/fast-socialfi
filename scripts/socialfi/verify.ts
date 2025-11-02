import { run } from "hardhat";
import fs from "fs";
import path from "path";
import { ethers } from "hardhat";

interface DeploymentAddresses {
  SocialToken: string;
  SocialNFT: string;
  ContentRegistry: string;
  Staking: string;
  Governance: string;
  deployer: string;
}

async function main() {
  console.log("====================================");
  console.log("  Contract Verification on Etherscan");
  console.log("====================================\n");

  // Load deployment addresses
  const addressesFile = path.join(process.cwd(), "deployments", "DEPLOYMENT_ADDRESSES.json");

  if (!fs.existsSync(addressesFile)) {
    throw new Error(`Deployment addresses file not found: ${addressesFile}`);
  }

  const addresses: DeploymentAddresses = JSON.parse(fs.readFileSync(addressesFile, "utf8"));

  console.log("Loaded deployment addresses:");
  console.log(`  SocialToken:      ${addresses.SocialToken}`);
  console.log(`  SocialNFT:        ${addresses.SocialNFT}`);
  console.log(`  ContentRegistry:  ${addresses.ContentRegistry}`);
  console.log(`  Staking:          ${addresses.Staking}`);
  console.log(`  Governance:       ${addresses.Governance}\n`);

  const mintingFee = ethers.parseEther("0.001");

  // Verify SocialToken
  console.log("📝 [1/5] Verifying SocialToken...");
  try {
    await run("verify:verify", {
      address: addresses.SocialToken,
      constructorArguments: [addresses.deployer],
    });
    console.log("✅ SocialToken verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ SocialToken already verified\n");
    } else {
      console.error("❌ SocialToken verification failed:", error.message, "\n");
    }
  }

  // Verify SocialNFT
  console.log("📝 [2/5] Verifying SocialNFT...");
  try {
    await run("verify:verify", {
      address: addresses.SocialNFT,
      constructorArguments: [addresses.deployer, mintingFee],
    });
    console.log("✅ SocialNFT verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ SocialNFT already verified\n");
    } else {
      console.error("❌ SocialNFT verification failed:", error.message, "\n");
    }
  }

  // Verify ContentRegistry
  console.log("📝 [3/5] Verifying ContentRegistry...");
  try {
    await run("verify:verify", {
      address: addresses.ContentRegistry,
      constructorArguments: [addresses.deployer, addresses.SocialToken],
    });
    console.log("✅ ContentRegistry verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ ContentRegistry already verified\n");
    } else {
      console.error("❌ ContentRegistry verification failed:", error.message, "\n");
    }
  }

  // Verify Staking
  console.log("📝 [4/5] Verifying Staking...");
  try {
    await run("verify:verify", {
      address: addresses.Staking,
      constructorArguments: [addresses.deployer, addresses.SocialToken],
    });
    console.log("✅ Staking verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ Staking already verified\n");
    } else {
      console.error("❌ Staking verification failed:", error.message, "\n");
    }
  }

  // Verify Governance
  console.log("📝 [5/5] Verifying Governance...");
  try {
    await run("verify:verify", {
      address: addresses.Governance,
      constructorArguments: [addresses.deployer, addresses.SocialToken],
    });
    console.log("✅ Governance verified\n");
  } catch (error: any) {
    if (error.message.includes("Already Verified")) {
      console.log("✅ Governance already verified\n");
    } else {
      console.error("❌ Governance verification failed:", error.message, "\n");
    }
  }

  console.log("====================================");
  console.log("✅ Verification Complete!");
  console.log("====================================\n");

  console.log("View contracts on Etherscan:");
  console.log(`SocialToken:      https://sepolia.etherscan.io/address/${addresses.SocialToken}`);
  console.log(`SocialNFT:        https://sepolia.etherscan.io/address/${addresses.SocialNFT}`);
  console.log(`ContentRegistry:  https://sepolia.etherscan.io/address/${addresses.ContentRegistry}`);
  console.log(`Staking:          https://sepolia.etherscan.io/address/${addresses.Staking}`);
  console.log(`Governance:       https://sepolia.etherscan.io/address/${addresses.Governance}\n`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
