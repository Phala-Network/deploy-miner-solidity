//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Useful for debugging. Remove when deploying to a live network.
import "forge-std/console.sol";

// Use openzeppelin to inherit battle-tested implementations (ERC20, ERC721, etc)
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./IMinerManagementInspect.sol";

contract MinerManagement is Ownable, IMinerManagementInspect {
    using Math for uint256;
    using SafeERC20 for IERC20;

    address public deployer;
    address public feeToken;
    uint256 public feeAmount;

    mapping(bytes32 miner => MinerInfo) public miners;
    uint256 public totalMiners;

    // uint256 constant DEFAULT_EXPIRATION_DURATION = 7 * 24 * 60 * 60;
    // For test purposes only
    uint256 constant DEFAULT_EXPIRATION_DURATION = 60;

    struct MinerInfo {
        address owner;
        uint256 expiration; // unix timestamp
        MinerState state;
    }

    enum MinerState {
        Undeployed,
        Active,
        Expired
    }

    modifier onlyDeployer() {
        require(_msgSender() == deployer, "Not deployer");
        _;
    }

    /**
     * Deployer is responsible for report online and offline of miner (worker)
     * The amount of fee token will be transferred from buyer account to deployer account
     * when execute payForMining()
     */
    constructor(address _deployer, address _feeToken, uint256 _feeAmount) Ownable(msg.sender) {
        deployer = _deployer;
        feeToken = _feeToken;
        feeAmount = _feeAmount;
    }

    function adminWithdrawFee() public onlyOwner {
        IERC20(feeToken).safeTransfer(owner(), IERC20(feeToken).balanceOf(address(this)));
    }

    function payForMining() external returns (bytes32) {
        // Transfer fee token from buyer to the contract address
        IERC20(feeToken).safeTransferFrom(msg.sender, address(this), feeAmount);

        // Save miner information
        bytes32 minerId = bytes32(totalMiners++);
        miners[minerId] = MinerInfo({owner: msg.sender, expiration: 0, state: MinerState.Undeployed});
        console.logString("Buy worker successfully");
        return minerId;
    }

    function reportMinerOnline(bytes32 minerId) external onlyDeployer {
        require(miners[minerId].owner > address(0), "Miner has not been paied");

        miners[minerId].state = MinerState.Active;
        miners[minerId].expiration = block.timestamp + DEFAULT_EXPIRATION_DURATION;
        console.logString("Miner online");
    }

    function reportMinerOffline(bytes32 minerId) external onlyDeployer {
        require(miners[minerId].owner > address(0), "Miner has not been paied");
        require(block.timestamp <= miners[minerId].expiration, "Miner has not expired");

        miners[minerId].state = MinerState.Expired;

        console.logString("Miner offline");
    }

    function hasPaied(bytes32 minerId) external view returns (bool) {
        return miners[minerId].owner > address(0);
    }

    function isActived(bytes32 minerId) external view returns (bool) {
        return miners[minerId].state == MinerState.Active;
    }

    function hasExpired(bytes32 minerId) external view returns (bool) {
        return block.timestamp > miners[minerId].expiration;
    }

    function minerDeployer() external view returns (address) {
        return deployer;
    }

    function minerOwner(bytes32 minerId) external view returns (address) {
        return miners[minerId].owner;
    }

    function getAllMiners() public view returns (MinerInfo[] memory) {
        MinerInfo[] memory result = new MinerInfo[](totalMiners);
        for (uint256 i = 0; i < totalMiners; ++i) {
            result[i] = miners[bytes32(i)];
        }
        return result;
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable {}
}
