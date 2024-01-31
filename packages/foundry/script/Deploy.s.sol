//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/MinerManagement.sol";
import "../contracts/MinerStaking.sol";
import "./DeployHelpers.s.sol";
import "./ERC20.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);
        ERC20 usdc = new ERC20("USD Coin", "USDC", 6);
        console.log("USDC (USD Coin) deployed at: %s", address(usdc));
        usdc.mint(vm.addr(deployerPrivateKey), 1000000000);
        console.log("Mint 1000000000 USDC to addr: %s", vm.addr(deployerPrivateKey));
        ERC20 testToken = new ERC20("Test Token", "TT", 18);
        console.log("TT (Test Token) deployed at: %s", address(testToken));
        testToken.mint(vm.addr(deployerPrivateKey), 10000 ether);
        console.log("Mint 10000000000000000000000 TT to addr: %s", vm.addr(deployerPrivateKey));

        MinerManagement minerManagement = new MinerManagement(vm.addr(deployerPrivateKey), address(usdc));
        console.log("MinerManagement deployed at: %s", address(minerManagement));
        MinerStaking minerStaking = new MinerStaking(address(minerManagement));
        console.log("MinerStaking deployed at: %s", address(minerStaking));
        testToken.approve(address(minerStaking), 10000 ether);
        minerStaking.createStaking(
            MinerStaking.StakingInfo({
                stakingToken: address(testToken),
                ticket: 1 ether,
                rewardToken: address(testToken),
                reward: 10 ether
            }),
            10000 ether
        );
        vm.stopBroadcast();

        deployments.push(ScaffoldETHDeploy.Deployment({name: "USDC", addr: address(usdc)}));
        deployments.push(ScaffoldETHDeploy.Deployment({name: "TestToken", addr: address(testToken)}));
        deployments.push(ScaffoldETHDeploy.Deployment({name: "MinerManagement", addr: address(minerManagement)}));
        deployments.push(ScaffoldETHDeploy.Deployment({name: "MinerStaking", addr: address(minerStaking)}));

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
