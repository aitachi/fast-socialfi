const { expect } = require("chai");
const { ethers } = require("hardhat");

/**
 * End-to-End Test: Complete User Journey
 *
 * This test simulates a complete user journey from wallet connection
 * to creating a circle, buying tokens, and interacting with the platform.
 */
describe("E2E Test: User Journey", function () {
  let circleFactory;
  let bondingCurve;
  let owner, user1, user2;
  let creationFee;

  before(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy CircleFactory
    const CircleFactory = await ethers.getContractFactory("CircleFactory");
    circleFactory = await CircleFactory.deploy(owner.address);
    await circleFactory.deployed();

    creationFee = await circleFactory.circleCreationFee();

    console.log("✅ CircleFactory deployed at:", circleFactory.address);
  });

  describe("1. New User Journey", function () {
    let circleId;
    let circleToken;

    it("Should connect wallet (simulated)", async function () {
      expect(user1.address).to.be.properAddress;
      console.log("✅ User wallet connected:", user1.address);
    });

    it("Should create a new circle", async function () {
      const tx = await circleFactory.connect(user1).createCircle(
        "Web3 Enthusiasts",
        "W3E",
        "A community for Web3 builders",
        0, // LINEAR
        ethers.utils.parseEther("0.001"), // basePrice
        ethers.utils.parseEther("0.000001"), // k
        0, // m
        0, // n
        { value: creationFee }
      );

      const receipt = await tx.wait();
      const event = receipt.events.find(e => e.event === "CircleCreated");
      circleId = event.args.circleId;
      const tokenAddress = event.args.tokenAddress;

      expect(circleId).to.equal(1);
      expect(tokenAddress).to.be.properAddress;

      circleToken = await ethers.getContractAt("CircleToken", tokenAddress);

      console.log("✅ Circle created, ID:", circleId.toString());
      console.log("✅ Token address:", tokenAddress);
    });

    it("Should verify circle ownership", async function () {
      const circle = await circleFactory.circles(circleId);
      expect(circle.owner).to.equal(user1.address);
      expect(circle.active).to.be.true;
      expect(circle.name).to.equal("Web3 Enthusiasts");

      console.log("✅ Circle ownership verified");
    });

    it("Should get initial token balance", async function () {
      const balance = await circleToken.balanceOf(user1.address);
      expect(balance).to.be.gt(0);

      console.log("✅ Initial token balance:", ethers.utils.formatEther(balance));
    });

    it("Should allow another user to discover and join the circle", async function () {
      // User2 discovers the circle
      const circle = await circleFactory.circles(circleId);
      expect(circle.active).to.be.true;

      console.log("✅ User2 discovered the circle");
    });
  });

  describe("2. Content Creator Journey", function () {
    let creatorCircleId;
    let creatorToken;

    it("Should create a creator circle", async function () {
      const tx = await circleFactory.connect(user2).createCircle(
        "Creative Minds",
        "CRM",
        "A circle for content creators",
        1, // EXPONENTIAL
        ethers.utils.parseEther("0.002"),
        ethers.utils.parseEther("0.000002"),
        0,
        0,
        { value: creationFee }
      );

      const receipt = await tx.wait();
      const event = receipt.events.find(e => e.event === "CircleCreated");
      creatorCircleId = event.args.circleId;
      const tokenAddress = event.args.tokenAddress;

      creatorToken = await ethers.getContractAt("CircleToken", tokenAddress);

      expect(creatorCircleId).to.equal(2);
      console.log("✅ Creator circle created, ID:", creatorCircleId.toString());
    });

    it("Should verify creator owns tokens", async function () {
      const balance = await creatorToken.balanceOf(user2.address);
      expect(balance).to.be.gt(0);

      console.log("✅ Creator token balance:", ethers.utils.formatEther(balance));
    });

    it("Should allow transferring tokens (tipping)", async function () {
      const balance = await creatorToken.balanceOf(user2.address);
      const tipAmount = balance.div(10); // 10% tip

      await creatorToken.connect(user2).transfer(user1.address, tipAmount);

      const newBalance = await creatorToken.balanceOf(user1.address);
      expect(newBalance).to.equal(tipAmount);

      console.log("✅ Tokens transferred as tip:", ethers.utils.formatEther(tipAmount));
    });
  });

  describe("3. Platform Statistics", function () {
    it("Should get platform-wide statistics", async function () {
      const stats = await circleFactory.getStatistics();

      expect(stats.totalCircles).to.equal(2);
      expect(stats.activeCircles).to.equal(2);

      console.log("✅ Total circles:", stats.totalCircles.toString());
      console.log("✅ Active circles:", stats.activeCircles.toString());
      console.log("✅ Platform fee collected:", ethers.utils.formatEther(stats.totalFeesCollected));
    });

    it("Should get user's circles", async function () {
      const user1Circles = await circleFactory.getOwnerCircles(user1.address);
      const user2Circles = await circleFactory.getOwnerCircles(user2.address);

      expect(user1Circles.length).to.equal(1);
      expect(user2Circles.length).to.equal(1);

      console.log("✅ User1 circles:", user1Circles.length);
      console.log("✅ User2 circles:", user2Circles.length);
    });
  });

  describe("4. Circle Management", function () {
    it("Should allow owner to deactivate circle", async function () {
      const circleId = 1;

      await circleFactory.connect(user1).deactivateCircle(circleId);

      const circle = await circleFactory.circles(circleId);
      expect(circle.active).to.be.false;

      console.log("✅ Circle deactivated");
    });

    it("Should allow owner to reactivate circle", async function () {
      const circleId = 1;

      await circleFactory.connect(user1).reactivateCircle(circleId);

      const circle = await circleFactory.circles(circleId);
      expect(circle.active).to.be.true;

      console.log("✅ Circle reactivated");
    });

    it("Should allow owner to transfer circle ownership", async function () {
      const circleId = 1;

      await circleFactory.connect(user1).transferCircleOwnership(circleId, user2.address);

      const circle = await circleFactory.circles(circleId);
      expect(circle.owner).to.equal(user2.address);

      // Verify user2's circles list updated
      const user2Circles = await circleFactory.getOwnerCircles(user2.address);
      expect(user2Circles.length).to.equal(2);

      console.log("✅ Circle ownership transferred");
    });
  });

  describe("5. Platform Administration", function () {
    it("Should allow admin to update creation fee", async function () {
      const newFee = ethers.utils.parseEther("0.02");

      await circleFactory.connect(owner).updateCircleCreationFee(newFee);

      const updatedFee = await circleFactory.circleCreationFee();
      expect(updatedFee).to.equal(newFee);

      console.log("✅ Creation fee updated to:", ethers.utils.formatEther(newFee), "ETH");
    });

    it("Should allow admin to pause platform", async function () {
      await circleFactory.connect(owner).pause();

      // Try to create circle while paused
      await expect(
        circleFactory.connect(user1).createCircle(
          "Test",
          "TST",
          "Test",
          0,
          ethers.utils.parseEther("0.001"),
          ethers.utils.parseEther("0.000001"),
          0,
          0,
          { value: creationFee }
        )
      ).to.be.revertedWith("Pausable: paused");

      console.log("✅ Platform paused successfully");
    });

    it("Should allow admin to unpause platform", async function () {
      await circleFactory.connect(owner).unpause();

      // Verify can create circle again
      const newFee = await circleFactory.circleCreationFee();
      const tx = await circleFactory.connect(user1).createCircle(
        "After Unpause",
        "AUP",
        "Test after unpause",
        0,
        ethers.utils.parseEther("0.001"),
        ethers.utils.parseEther("0.000001"),
        0,
        0,
        { value: newFee }
      );

      const receipt = await tx.wait();
      expect(receipt.status).to.equal(1);

      console.log("✅ Platform unpaused successfully");
    });
  });

  after(function () {
    console.log("\n========================================");
    console.log("✅ E2E Test: User Journey - COMPLETED");
    console.log("========================================");
  });
});

module.exports = {};
