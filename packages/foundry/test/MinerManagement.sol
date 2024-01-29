// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/mocks/MockERC20.sol";
import "../contracts/MinerManagement.sol";

contract MinerManagementTest is Test {
    MinerManagement public minerManagement;
    MockERC20 public usdc;
    MockERC20 public testToken;

    function setUp() public {
        usdc = deployMockERC20("USD Coin", "USDC", 6);
        testToken = deployMockERC20("Test Token", "TT", 18);
        // Pay 100 USDC for a worker
        minerManagement = new MinerManagement(DEFAULT_SENDER, address(usdc), 100000000);
    }

    function testPayMiningWithUSDC() public {
        bytes32 minerId = minerManagement.payForMining();

        require(IERC20(address(usdc)).balanceOf(address(minerManagement)) == 100000000, "Failed to buy worker");
        require(minerManagement.hasPaied(minerId), "Incorrect miner state");

        minerManagement.reportMinerOnline(minerId);
        require(minerManagement.isActived(minerId), "Incorrect miner state");
        require(!minerManagement.hasExpired(minerId), "Incorrect miner state");

        vm.warp(60);
        require(minerManagement.hasExpired(minerId), "Incorrect miner state");
    }
}
