import { expect } from "chai";
import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import type { Savings, MockERC20 } from "../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";

describe("Savings", () => {
  // Deployment fixture
  async function deploySavingsFixture() {
    const [owner, user] = await ethers.getSigners();
    const INITIAL_SUPPLY = ethers.parseEther("1000000");

    // Deploy mock stable coin
    const mockERC20Factory = await ethers.getContractFactory("MockERC20");
    const stableCoin = (await mockERC20Factory.deploy(
      "Mock USDC",
      "mUSDC",
      INITIAL_SUPPLY
    )) as unknown as MockERC20;
    await stableCoin.waitForDeployment();

    // Deploy Savings contract
    const savingsFactory = await ethers.getContractFactory("Savings");
    const savings = (await savingsFactory.deploy(
      "Test Savings",
      await stableCoin.getAddress()
    )) as unknown as Savings;
    await savings.waitForDeployment();

    // Approve savings contract to spend tokens
    await stableCoin.approve(await savings.getAddress(), INITIAL_SUPPLY);

    return { savings, stableCoin, owner, user, INITIAL_SUPPLY };
  }

  describe("Constructor", () => {
    it("should initialize with correct parameters", async () => {
      const { savings, owner } = await loadFixture(deploySavingsFixture);
      expect(await savings.getSavingPlanCount()).to.equal(0);
      expect(await savings.owner()).to.equal(owner.address);
    });

    it("should revert if stableToken address is zero", async () => {
      const savingsFactory = await ethers.getContractFactory("Savings");
      const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
      const deployPromise = savingsFactory.deploy("Test Savings", ZERO_ADDRESS);
      await expect(deployPromise).to.be.revertedWithCustomError(
        await deployPromise.catch(e => e.contract),
        "SavingsInvalidAmount"
      );
    });
  });

  describe("createSavingPlan", () => {
    const planName = "Test Plan";
    const amount = ethers.parseEther("100");
    const target = ethers.parseEther("1000");
    const unlockTime = 30; // 30 days

    it("should create a fixed saving plan successfully", async () => {
      const { savings, owner } = await loadFixture(deploySavingsFixture);
      const tx = await savings.createSavingPlan(
        planName,
        true,
        amount,
        target,
        unlockTime
      );

      const planId = 0;
      await expect(tx)
        .to.emit(savings, "SavingPlanCreated")
        .withArgs(planId, planName, true, target);

      await expect(tx)
        .to.emit(savings, "FundsDeposited")
        .withArgs(owner.address, planId, amount, amount);

      const plan = await savings.getSavingPlan(planId);
      expect(plan.savingPlanName).to.equal(planName);
      expect(plan.fixedPlan).to.be.true;
      expect(plan.total).to.equal(amount);
      expect(plan.target).to.equal(target);
    });

    it("should revert if amount is zero", async () => {
      const { savings } = await loadFixture(deploySavingsFixture);
      await expect(
        savings.createSavingPlan(planName, true, 0, target, unlockTime)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidAmount");
    });

    it("should revert if unlock time is zero", async () => {
      const { savings } = await loadFixture(deploySavingsFixture);
      await expect(
        savings.createSavingPlan(planName, true, amount, target, 0)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidUnlockTime");
    });

    it("should revert if caller is not owner", async () => {
      const { savings, user } = await loadFixture(deploySavingsFixture);
      await expect(
        savings.connect(user).createSavingPlan(planName, true, amount, target, unlockTime)
      ).to.be.revertedWithCustomError(savings, "OwnableUnauthorizedAccount");
    });
  });

  describe("deposit", () => {
    async function createPlanFixture() {
      const deployment = await deploySavingsFixture();
      const { savings } = deployment;
      
      const planName = "Test Plan";
      const initialAmount = ethers.parseEther("100");
      const target = ethers.parseEther("1000");
      const unlockTime = 30;
      
      await savings.createSavingPlan(
        planName,
        true,
        initialAmount,
        target,
        unlockTime
      );
      
      return { ...deployment, planName, initialAmount, target, unlockTime, planId: 0 };
    }

    it("should deposit funds successfully", async () => {
      const { savings, owner, initialAmount, planId } = await loadFixture(createPlanFixture);
      const depositAmount = ethers.parseEther("50");
      const tx = await savings.deposit(planId, depositAmount);

      await expect(tx)
        .to.emit(savings, "FundsDeposited")
        .withArgs(owner.address, planId, depositAmount, initialAmount + depositAmount);

      const plan = await savings.getSavingPlan(planId);
      expect(plan.total).to.equal(initialAmount + depositAmount);
    });

    it("should revert if amount is zero", async () => {
      const { savings, planId } = await loadFixture(createPlanFixture);
      await expect(
        savings.deposit(planId, 0)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidAmount");
    });

    it("should revert if plan does not exist", async () => {
      const { savings } = await loadFixture(createPlanFixture);
      await expect(
        savings.deposit(999, ethers.parseEther("50"))
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidPlanId");
    });

    it("should revert if caller is not owner", async () => {
      const { savings, user, planId } = await loadFixture(createPlanFixture);
      await expect(
        savings.connect(user).deposit(planId, ethers.parseEther("50"))
      ).to.be.revertedWithCustomError(savings, "OwnableUnauthorizedAccount");
    });
  });

  describe("withdrawFromSavingPlan", () => {
    async function createPlanFixture() {
      const deployment = await deploySavingsFixture();
      const { savings } = deployment;
      
      const planName = "Test Plan";
      const amount = ethers.parseEther("100");
      const target = ethers.parseEther("1000");
      const unlockTime = 30;
      
      await savings.createSavingPlan(
        planName,
        true,
        amount,
        target,
        unlockTime
      );
      
      return { ...deployment, planName, amount, target, unlockTime, planId: 0 };
    }

    it("should withdraw from fixed plan after unlock time", async () => {
      const { savings, owner, amount, planId, unlockTime } = await loadFixture(createPlanFixture);
      await time.increase(time.duration.days(unlockTime + 1));

      const tx = await savings.withdrawFromSavingPlan(planId);

      await expect(tx)
        .to.emit(savings, "FundsWithdrawn")
        .withArgs(owner.address, planId, amount);

      const plan = await savings.getSavingPlan(planId);
      expect(plan.total).to.equal(0);
      expect(plan.target).to.equal(0);
      expect(plan.unlockTime).to.equal(0);
    });

    it("should withdraw from flexible plan at any time", async () => {
      const { savings, owner, amount, target, unlockTime } = await loadFixture(createPlanFixture);
      
      // Create flexible plan
      await savings.createSavingPlan(
        "Flexible Plan",
        false,
        amount,
        target,
        unlockTime
      );
      const flexiblePlanId = 1;

      const tx = await savings.withdrawFromSavingPlan(flexiblePlanId);

      await expect(tx)
        .to.emit(savings, "FundsWithdrawn")
        .withArgs(owner.address, flexiblePlanId, amount);
    });

    it("should revert if withdrawing from fixed plan before unlock time", async () => {
      const { savings, planId } = await loadFixture(createPlanFixture);
      await expect(
        savings.withdrawFromSavingPlan(planId)
      ).to.be.revertedWithCustomError(savings, "SavingsUnlockTimeNotReached");
    });

    it("should revert if plan does not exist", async () => {
      const { savings } = await loadFixture(createPlanFixture);
      await expect(
        savings.withdrawFromSavingPlan(999)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidPlanId");
    });

    it("should revert if caller is not owner", async () => {
      const { savings, user, planId } = await loadFixture(createPlanFixture);
      await expect(
        savings.connect(user).withdrawFromSavingPlan(planId)
      ).to.be.revertedWithCustomError(savings, "OwnableUnauthorizedAccount");
    });
  });

  describe("View Functions", () => {
    async function createPlanFixture() {
      const deployment = await deploySavingsFixture();
      const { savings } = deployment;
      
      const planName = "Test Plan";
      const amount = ethers.parseEther("100");
      const target = ethers.parseEther("1000");
      const unlockTime = 30;
      
      await savings.createSavingPlan(
        planName,
        true,
        amount,
        target,
        unlockTime
      );
      
      return { ...deployment, planName, amount, target, unlockTime, planId: 0 };
    }

    it("should return correct saving plan name", async () => {
      const { savings, planId, planName } = await loadFixture(createPlanFixture);
      expect(await savings.getSavingPlanName(planId)).to.equal(planName);
    });

    it("should return correct contract balance", async () => {
      const { savings, amount } = await loadFixture(createPlanFixture);
      expect(await savings.getContractBalance()).to.equal(amount);
    });

    it("should return correct saving plan count", async () => {
      const { savings } = await loadFixture(createPlanFixture);
      expect(await savings.getSavingPlanCount()).to.equal(1);
    });

    it("should return correct saving plan details", async () => {
      const { savings, planId, planName, amount, target } = await loadFixture(createPlanFixture);
      const plan = await savings.getSavingPlan(planId);
      expect(plan.savingPlanName).to.equal(planName);
      expect(plan.fixedPlan).to.be.true;
      expect(plan.total).to.equal(amount);
      expect(plan.target).to.equal(target);
    });

    it("should return correct saving plan balance", async () => {
      const { savings, planId, amount } = await loadFixture(createPlanFixture);
      expect(await savings.getSavingPlanBalance(planId)).to.equal(amount);
    });

    it("should revert when querying invalid plan id", async () => {
      const { savings } = await loadFixture(createPlanFixture);
      await expect(
        savings.getSavingPlanName(999)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidPlanId");

      await expect(
        savings.getSavingPlan(999)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidPlanId");

      await expect(
        savings.getSavingPlanBalance(999)
      ).to.be.revertedWithCustomError(savings, "SavingsInvalidPlanId");
    });
  });
});