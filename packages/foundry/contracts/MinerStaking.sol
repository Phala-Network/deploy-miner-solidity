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

contract MinerStaking is Ownable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    struct StakingInfo {
        // The staking token
        address stakingToken;
        // The amount of staking token for each staker
        uint256 ticket;
        // The reward token that will be distributed to depositor
        address rewardToken;
        // The amount of reward per block
        uint256 reward;
    }

    address private minerManagement;
    StakingInfo stakingInfo;
    uint256 public rewardBalance;
    uint256 public totalMiners;
    mapping(bytes32 => bool) public depositRecord;
    mapping(bytes32 => uint256) public lastUpdatedBlock;
    mapping(bytes32 => uint256) public pendingReward;

    modifier onlyMinerDeployer() {
        require(_msgSender() == IMinerManagementInspect(minerManagement).minerDeployer(), "Not deployer");
        _;
    }

    modifier onlyMinerOwner(bytes32 minerId) {
        require(_msgSender() == IMinerManagementInspect(minerManagement).minerOwner(minerId), "Not miner owner");
        _;
    }

    /**
     * Deployer is responsible for report online and offline of miner (worker)
     * The amount of fee token will be transferred from buyer account to deployer account
     * when execute payForMining()
     */
    constructor(address _minerManagement) Ownable(msg.sender) {
        minerManagement = _minerManagement;
        totalMiners = 0;
    }

    // Miner owner create staking and topup reward token
    function createStaking(StakingInfo memory info, uint256 topupAmount)
        external
        onlyOwner
    {
        // Transfer reward token to this contract
        IERC20(info.rewardToken).safeTransferFrom(msg.sender, address(this), topupAmount);
        rewardBalance = topupAmount;
        stakingInfo = info;
    }

    // Miner deployer pause staking when miner offline
    function pauseStaking(bytes32 minerId) external onlyMinerDeployer {
        _update(minerId);
        lastUpdatedBlock[minerId] = MAX_UINT256;
    }

    // Miner deployer unpause staking when miner back to online
    function unpauseStaking(bytes32 minerId) external onlyMinerDeployer {
        lastUpdatedBlock[minerId] = block.number;
    }

    // User deposit fund
    function deposit(bytes32 minerId) external onlyMinerOwner(minerId) {
        require(IMinerManagementInspect(minerManagement).hasPaied(minerId), "Buy worker first");
        require(IMinerManagementInspect(minerManagement).isActived(minerId), "Worker has not online");

        StakingInfo memory localStakingInfo = stakingInfo;
        require(block.number >= lastUpdatedBlock[minerId], "Can not deposit");
        require(!depositRecord[minerId], "Already deposited");

        _update(minerId);

        IERC20(localStakingInfo.stakingToken).safeTransferFrom(msg.sender, address(this), localStakingInfo.ticket);
        depositRecord[minerId] = true;
        ++totalMiners;
        lastUpdatedBlock[minerId] = block.number;
    }

    // User withdraw fund
    function withdraw(bytes32 minerId) external {
        require(depositRecord[minerId], "Has not stake to this miner");
        StakingInfo memory localStakingInfo = stakingInfo;

        // Refund tiket
        IERC20(localStakingInfo.stakingToken).safeTransfer(msg.sender, localStakingInfo.ticket);

        _update(minerId);

        // Distribute reward belong to this staker
        uint256 reward = pendingReward[minerId];
        require(rewardBalance > reward, "Insufficient reward");
        IERC20(localStakingInfo.rewardToken).safeTransfer(msg.sender, reward);

        // Update reward info
        pendingReward[minerId] = 0;
        rewardBalance -= reward;

        depositRecord[minerId] = false;
        --totalMiners;
        lastUpdatedBlock[minerId] = block.number;
    }

    // Calculate pending reward that miner currently has
    function getReward(bytes32 minerId) public view returns (uint256) {
        if (!depositRecord[minerId] || lastUpdatedBlock[minerId] > block.number) {
            return 0;
        }
        uint256 totalNonSavedReward = stakingInfo.reward * (block.number - lastUpdatedBlock[minerId]);
        // Saved pending reward + non-saved pending reward
        return pendingReward[minerId] + (totalNonSavedReward / totalMiners);
    }

    // Update reward, use for look for demo purpose only
    function _update(bytes32 minerId) internal {
        uint256 lastBlock = lastUpdatedBlock[minerId];
        if (!depositRecord[minerId] || block.number <= lastBlock) {
            return;
        }

        uint256 totalReward = stakingInfo.reward * (block.number - lastBlock);
        pendingReward[minerId] += totalReward / totalMiners;  // approximate
        lastUpdatedBlock[minerId] = block.number;
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable {}
}
