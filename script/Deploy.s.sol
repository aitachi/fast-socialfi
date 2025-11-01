// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/core/CircleFactory.sol";
import "../contracts/core/BondingCurve.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy platform treasury (use deployer for now)
        address platformTreasury = deployer;
        console.log("Platform Treasury:", platformTreasury);

        // Deploy CircleFactory (will deploy BondingCurve internally)
        CircleFactory factory = new CircleFactory(platformTreasury);
        console.log("CircleFactory deployed at:", address(factory));

        // Get BondingCurve address from factory
        address bondingCurve = factory.bondingCurveImpl();
        console.log("BondingCurve deployed at:", bondingCurve);

        // Optional: Create a test circle
        if (block.chainid == 31337 || block.chainid == 11155111) { // Anvil or Sepolia
            console.log("\nCreating test circle...");

            uint256 circleId = factory.createCircle{value: 0.01 ether}(
                "Web3 Builders",
                "W3B",
                "A community for Web3 developers and builders",
                BondingCurve.CurveType.LINEAR,
                0.001 ether,  // base price
                1e15,         // slope
                0,            // unused for linear
                0             // unused for linear
            );

            console.log("Test circle created with ID:", circleId);

            // Get circle details
            (
                uint256 id,
                address owner,
                address tokenAddress,
                address curve,
                string memory name,
                string memory symbol,
                ,
                bool active,

            ) = factory.circles(circleId);

            console.log("\nCircle Details:");
            console.log("  ID:", id);
            console.log("  Owner:", owner);
            console.log("  Token:", tokenAddress);
            console.log("  Bonding Curve:", curve);
            console.log("  Name:", name);
            console.log("  Symbol:", symbol);
            console.log("  Active:", active);
        }

        vm.stopBroadcast();

        // Write deployment info to file
        console.log("\n=== Deployment Summary ===");
        console.log("CircleFactory:", address(factory));
        console.log("BondingCurve:", bondingCurve);
        console.log("Platform Treasury:", platformTreasury);
        console.log("Network:", block.chainid);
        console.log("========================\n");

        // Save addresses to .env format
        console.log("Add these to your .env file:");
        console.log("FACTORY_ADDRESS=%s", address(factory));
        console.log("BONDING_CURVE_ADDRESS=%s", bondingCurve);
        console.log("PLATFORM_TREASURY=%s", platformTreasury);
    }
}
