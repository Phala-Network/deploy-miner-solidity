// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/mocks/MockERC20.sol";
import "../contracts/MinerManagement.sol";
import "../contracts/MinerStaking.sol";

contract Token_ERC20 is MockERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) {
        initialize(name, symbol, decimals);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

contract MinerStakingTest is Test {
    MinerManagement public minerManagement;
    MinerStaking public minerStaking;
    // Token used to buy worker
    Token_ERC20 public usdc;
    // Test token for staking and staking reward distribution
    Token_ERC20 public testToken;
    address deployer = address(DEFAULT_SENDER);
    address minerOwner = address(1);
    address staker1 = address(2);
    address staker2 = address(3);
    MinerStaking.StakingInfo stakingInfo;

    function setUp() public {
        usdc = new Token_ERC20("USD Coin", "USDC", 6);
        usdc.mint(minerOwner, 1000000000);
        assertEq(usdc.totalSupply(), 1000000000);
        assertEq(usdc.balanceOf(address(minerOwner)), 1000000000);

        testToken = new Token_ERC20("Test Token", "TT", 18);
        testToken.mint(minerOwner, 10000000000000000000000);
        testToken.mint(staker1, 10000000000000000000000);
        testToken.mint(staker2, 10000000000000000000000);
        assertEq(testToken.totalSupply(), 30000000000000000000000);
        assertEq(testToken.balanceOf(address(minerOwner)), 10000000000000000000000);
        assertEq(testToken.balanceOf(address(staker1)), 10000000000000000000000);
        assertEq(testToken.balanceOf(address(staker2)), 10000000000000000000000);

        // Config to pay 100 USDC for a worker
        minerManagement = new MinerManagement(deployer, address(usdc), 100000000);
        minerStaking = new MinerStaking(address(minerManagement));

        stakingInfo = MinerStaking.StakingInfo({
            owner: minerOwner,
            stakingToken: address(testToken),
            // 1 TT
            ticket: 10000000000000000,
            rewardToken: address(testToken),
            // 10 TT per block
            reward: 10000000000000000000,
            lastUpdateBlock: 0
        });
    }

    function testStakingWithTestToken() public {
        // Should failed if hasn't brought worker
        vm.expectRevert("Not miner owner");
        vm.prank(address(minerOwner));
        minerStaking.createStaking(
            bytes32(0),
            stakingInfo,
            10000000000000000000000
        );

        // Buy worker
        vm.prank(address(minerOwner));
        usdc.approve(address(minerManagement), 100000000);
        vm.prank(address(minerOwner));
        bytes32 minerId = minerManagement.payForMining();
        require(minerManagement.hasPaied(minerId), "Miner should be paied");

        // Should failed if worker hasn't online
        vm.expectRevert("Worker has not online");
        vm.prank(address(minerOwner));
        minerStaking.createStaking(
            minerId,
            stakingInfo,
            10000000000000000000000
        );

        vm.prank(address(deployer));
        minerManagement.reportMinerOnline(minerId);
        require(minerManagement.isActived(minerId), "Miner should be actived");
        require(!minerManagement.hasExpired(minerId), "Miner should not expired");

        // Create staking should work
        vm.prank(address(minerOwner));
        testToken.approve(address(minerStaking), 10000000000000000000000);
        vm.prank(address(minerOwner));
        minerStaking.createStaking(
            minerId,
            stakingInfo,
            10000000000000000000000
        );

        // Staker1 deposit 1 TT
        vm.prank(address(staker1));
        testToken.approve(address(minerStaking), 1000000000000000000);
        vm.prank(address(staker1));
        minerStaking.deposit(minerId);
        assertEq(minerStaking.getDepositors(minerId).length, 1);
        assertEq(minerStaking.getDepositors(minerId)[0], address(staker1));

        // block number start with 1, increase block number to 2,
        // then Staker1 should have 10 pending for reward
        vm.roll(2);
        assertEq(minerStaking.getReward(minerId, address(staker1)), 10000000000000000000);

        // Staker2 deposit 1 TT
        vm.prank(address(staker2));
        testToken.approve(address(minerStaking), 1000000000000000000);
        vm.prank(address(staker2));
        minerStaking.deposit(minerId);
        assertEq(minerStaking.getDepositors(minerId).length, 2);
        assertEq(minerStaking.getDepositors(minerId)[1], address(staker2));

        // 10 blocks passed, staker1 should have (10 + 50) TT pending reward,
        // and Staker2 should have 50 TT pending reward
        vm.roll(2 + 10);
        assertEq(minerStaking.getReward(minerId, address(staker1)), 60000000000000000000);
        assertEq(minerStaking.getReward(minerId, address(staker2)), 50000000000000000000);
    }
}