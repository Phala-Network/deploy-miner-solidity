// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/mocks/MockERC20.sol";
import "../contracts/MinerManagement.sol";

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

contract MinerManagementTest is Test {
    MinerManagement public minerManagement;
    Token_ERC20 public usdc;

    function setUp() public {
        usdc = new Token_ERC20("USD Coin", "USDC", 6);
        usdc.mint(DEFAULT_SENDER, 1000000000);
        minerManagement = new MinerManagement(DEFAULT_SENDER, address(usdc));
    }

    function testPayMiningWithUSDC() public {
        vm.prank(address(DEFAULT_SENDER));
        usdc.approve(address(minerManagement), 5000000);
        vm.prank(address(DEFAULT_SENDER));
        // Buy 24 hours
        bytes32 minerId = minerManagement.payForMining(5000000);

        require(IERC20(address(usdc)).balanceOf(address(minerManagement)) == 5000000, "Failed to buy worker");
        require(minerManagement.hasPaied(minerId), "Miner should be paied");

        vm.prank(address(DEFAULT_SENDER));
        minerManagement.reportOnline(minerId, "phala://0xAAAAA");
        require(minerManagement.isActived(minerId), "Miner should be actived");
        require(!minerManagement.hasExpired(minerId), "Miner should not expired");

        // block.timestamp start with 1, increase 24 hours
        vm.warp(1 + 24 * 60 * 60);
        require(minerManagement.hasExpired(minerId), "Miner should expired");
    }
}
