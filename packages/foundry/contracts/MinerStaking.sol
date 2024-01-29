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

contract MinerManagement is Ownable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    struct StakingInfo {
        // Owner of the miner, e.g. owner of the staking event
        address owner;
        // The staking token
        address stakingToken;
        // The amount of staking token for each staker
        uint256 ticket;
        // The reward token that will be distributed to depositor
        address rewardToken;
        // The amount of reward per block
        uint256 reward;
        // Last update block number
        uint256 lastUpdateBlock;
    }

    address private minerManagement;
    mapping(bytes32 => StakingInfo) public stakingInfo;
    mapping(bytes32 => mapping(address => bool)) public depositRecord;
    mapping(bytes32 => address[]) depositorList;
    mapping(bytes32 => mapping(address => uint256)) public pendingReward;
    mapping(bytes32 => uint256) public rewardBalance;

    modifier onlyMinerDeployer() {
        require(_msgSender() == IMinerManagementInspect(minerManagement).minerDeployer(), "Not deployer");
        _;
    }

    modifier onlyMinerOwner(bytes32 minerId) {
        require(_msgSender() == IMinerManagementInspect(minerManagement).minerOwner(minerId), "Not deployer");
        _;
    }

    /**
     * Deployer is responsible for report online and offline of miner (worker)
     * The amount of fee token will be transferred from buyer account to deployer account
     * when execute payForMining()
     */
    constructor(address _minerManagement) Ownable(msg.sender) {
        minerManagement = _minerManagement;
    }

    // Miner owner create staking and topup reward token
    function createStaking(bytes32 minerId, StakingInfo memory info, uint256 topupAmount)
        external
        onlyMinerOwner(minerId)
    {
        require(IMinerManagementInspect(minerManagement).hasPaied(minerId), "Buy worker first");
        require(IMinerManagementInspect(minerManagement).isActived(minerId), "Worker has not online");
        require(info.owner == msg.sender, "Miner mismatch");

        // Transfer reward token to this contract
        IERC20(info.rewardToken).safeTransferFrom(msg.sender, address(this), topupAmount);
        rewardBalance[minerId] = topupAmount;

        info.lastUpdateBlock = block.number;
        stakingInfo[minerId] = info;
    }

    // Miner deployer pause staking when miner offline
    function pauseStaking(bytes32 minerId) external onlyMinerDeployer {}

    // Miner deployer unpause staking when miner back to online
    function unpauseStaking(bytes32 minerId) external onlyMinerDeployer {}

    // User deposit fund
    function deposit(bytes32 minerId) external {
        require(!depositRecord[minerId][msg.sender], "Already deposited");

        _update(minerId);

        StakingInfo memory localStakingInfo = stakingInfo[minerId];
        IERC20(localStakingInfo.stakingToken).safeTransferFrom(msg.sender, address(this), localStakingInfo.ticket);
        depositRecord[minerId][msg.sender] = true;

        // Update staking info
        address[] storage localDepositorList = depositorList[minerId];
        localDepositorList.push(msg.sender);
        depositorList[minerId] = localDepositorList;
    }

    // User withdraw fund
    function withdraw(bytes32 minerId) external {
        require(depositRecord[minerId][msg.sender], "Has not stake to this miner");
        StakingInfo memory localStakingInfo = stakingInfo[minerId];

        // Refund tiket
        IERC20(localStakingInfo.stakingToken).safeTransfer(msg.sender, localStakingInfo.ticket);

        _update(minerId);

        // Distribute reward belong to this staker
        uint256 reward = pendingReward[minerId][msg.sender];
        require(rewardBalance[minerId] > reward, "Insufficient reward");
        IERC20(localStakingInfo.rewardToken).safeTransfer(msg.sender, reward);

        // Update staking info
        rewardBalance[minerId] -= reward;

        // TODO: remove from depositor list
    }

    // Calculate reward based on share
    function getReward(bytes32 minerId, address depositor) public view returns (uint256) {
        return pendingReward[minerId][depositor];
    }

    // Update reward, use for look for demo purpose only
    function _update(bytes32 minerId) internal {
        StakingInfo memory localStakingInfo = stakingInfo[minerId];

        uint256 totalReward = localStakingInfo.reward * (block.number - localStakingInfo.lastUpdateBlock);
        for (uint256 i = 0; i < depositorList[minerId].length; i++) {
            pendingReward[minerId][depositorList[minerId][i]] += totalReward / depositorList[minerId].length;
        }
        localStakingInfo.lastUpdateBlock = block.number;
        stakingInfo[minerId] = localStakingInfo;
    }

    /**
     * Function that allows the contract to receive ETH
     */
    receive() external payable {}
}
