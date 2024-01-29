//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IMinerManagementInspect {
    function minerDeployer() external returns (address);
    function minerOwner(bytes32 minerId) external returns (address);
    function hasPaied(bytes32 minerId) external view returns (bool);
    function isActived(bytes32 minerId) external view returns (bool);
    function hasExpired(bytes32 minerId) external view returns (bool);
}
