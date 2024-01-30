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
        console.logString(string.concat("USDC (USD Coin) deployed at: ", vm.toString(address(usdc))));
        usdc.mint(vm.addr(deployerPrivateKey), 1000000000);
        console.logString(string.concat("Mint 1000000000 USDC to addr: ", vm.toString(vm.addr(deployerPrivateKey))));
        ERC20 testToken = new ERC20("Test Token", "TT", 18);
        console.logString(string.concat("TT (Test Token) deployed at: ", vm.toString(address(testToken))));
        testToken.mint(vm.addr(deployerPrivateKey), 10000000000000000000000);
        console.logString(string.concat("Mint 10000000000000000000000 TT to addr: ", vm.toString(vm.addr(deployerPrivateKey))));

        MinerManagement minerManagement = new MinerManagement(vm.addr(deployerPrivateKey), address(usdc), 100000000);
        console.logString(string.concat("MinerManagement deployed at: ", vm.toString(address(minerManagement))));
        MinerStaking minerStaking = new MinerStaking(address(minerManagement));
        console.logString(string.concat("MinerStaking deployed at: ", vm.toString(address(minerStaking))));
        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
