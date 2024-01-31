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
    address minerOwner2 = address(2);
    MinerStaking.StakingInfo stakingInfo;

    function setUp() public {
        usdc = new Token_ERC20("USD Coin", "USDC", 6);
        usdc.mint(minerOwner, 1000000000);
        usdc.mint(minerOwner2, 1000000000);
        assertEq(usdc.totalSupply(), 2000000000);
        assertEq(usdc.balanceOf(minerOwner), 1000000000);
        assertEq(usdc.balanceOf(minerOwner2), 1000000000);

        testToken = new Token_ERC20("Test Token", "TT", 18);
        testToken.mint(address(this), 10000 ether);
        testToken.mint(minerOwner, 20000 ether);
        testToken.mint(minerOwner2, 20000 ether);
        assertEq(testToken.totalSupply(), 50000 ether);
        assertEq(testToken.balanceOf(address(minerOwner)), 20000 ether);
        assertEq(testToken.balanceOf(address(minerOwner2)), 20000 ether);

        // Config to pay 100 USDC for a worker
        minerManagement = new MinerManagement(deployer, address(usdc));
        minerStaking = new MinerStaking(address(minerManagement));

        stakingInfo = MinerStaking.StakingInfo({
            stakingToken: address(testToken),
            // 1 TT
            ticket: 1 ether,
            rewardToken: address(testToken),
            // 10 TT per block
            reward: 10 ether
        });
        testToken.approve(address(minerStaking), 10000 ether);
        minerStaking.createStaking(stakingInfo, 10000 ether);

        vm.label(minerOwner, "MinerOwner");
        vm.label(minerOwner2, "MinerOwner2");        
    }

    function testStakingWithTestToken() public {
        // Should failed if hasn't brought worker
        vm.expectRevert("Not miner owner");
        vm.startPrank(minerOwner);
        minerStaking.deposit(bytes32(0));

        // Buy worker
        vm.startPrank(minerOwner);
        usdc.approve(address(minerManagement), 5000000);
        bytes32 minerId = minerManagement.payForMining(5000000);
        require(minerManagement.hasPaied(minerId), "Miner should be paied");
        require(!minerManagement.hasExpired(minerId), "Miner should not expired");
        vm.startPrank(minerOwner2);
        usdc.approve(address(minerManagement), 5000000);
        bytes32 minerId2 = minerManagement.payForMining(5000000);
        require(minerManagement.hasPaied(minerId2), "Miner should be paied");
        require(!minerManagement.hasExpired(minerId2), "Miner should not expired");

        // Should failed if worker hasn't online
        vm.expectRevert("Worker has not online");
        vm.startPrank(minerOwner);
        minerStaking.deposit(minerId);

        vm.startPrank(address(deployer));
        minerManagement.reportOnline(minerId, "phala://0xAAAAA");
        minerManagement.reportOnline(minerId2, "phala://0xBBBBB");
        require(minerManagement.isActived(minerId), "Miner should be actived");

        // // Create staking should work
        // vm.prank(minerOwner);
        // testToken.approve(address(minerStaking), 10000 ether);
        // minerStaking.createStaking(minerId, stakingInfo, 10000 ether);

        // Staker1 deposit 1 TT
        vm.startPrank(minerOwner);
        testToken.approve(address(minerStaking), 1 ether);
        minerStaking.deposit(minerId);
        assertTrue(minerStaking.depositRecord(minerId));

        // block number start with 1, increase block number to 2,
        // then Staker1 should have 10 pending for reward
        vm.roll(2);
        assertEq(minerStaking.getReward(minerId), 10 ether);

        // Staker2 deposit 1 TT
        vm.startPrank(minerOwner2);
        testToken.approve(address(minerStaking), 1 ether);
        minerStaking.deposit(minerId2);
        assertTrue(minerStaking.depositRecord(minerId2));

        // 10 blocks passed, miner1 should have (110 / 2 = 55) TT pending reward,
        // and miner2 should have (100 / 2 = 50) TT pending reward
        vm.roll(2 + 10);
        assertEq(minerStaking.getReward(minerId), 55 ether);
        assertEq(minerStaking.getReward(minerId2), 50 ether);
    }
}
