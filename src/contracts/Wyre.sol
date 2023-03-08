// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWyre} from "../interfaces/IWyre.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
* @title Wyre.
* @author Tecmie Labs.
* @notice Version: v0.0.1.
* @dev Wyre - An On-Chain Payroll Infrastructure.
*/

contract Wyre is IWyre, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32; // Using ECDSA for hashes.

    /// @dev To help randomize hashes for signatures.
    bytes32 private constant DOMAIN_SEPARATOR = keccak256("WYRE_PAYROLL_INFRASTRUCTURE_V0.1.1");
    // keccak256("RewardContractor(address contractor, uint256 reward, address token, uint256 seed, uint256 deadline)");
    bytes32 private constant MESSAGE_HASH = 0xc06122abc84bf5362ffea52f0a63cfcb41f7f28813e5533b4c01e2b4cb21d83c;

    mapping(bytes32 => bool) private usedRSignatures;

    /// @dev Makes sure that all incoming ETH are accounted for.
    receive() external payable {}

    /**
    * @inheritdoc IWyre
    */
    function fundContractWithETH() external payable returns (bool) {
        emit Fund(msg.value);
        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function fundContractWithToken(
        address token,
        uint256 amount
    ) external onlyOwner returns (bool) {
        if (token == address(0)) revert ZeroAddress();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit FundToken(token, amount);
        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function rewardEmployeesWithETH(
        address[] calldata employees,
        uint256[] calldata rewards
    ) external onlyOwner nonReentrant returns (bool) {
        if (employees.length != rewards.length) revert RecipientRewardsMismatch();
        uint256 sum = _getSum(rewards);

        if (sum > address(this).balance) revert InsufficientFunds();

        for (uint256 i; i < employees.length; ) {
            /// @dev Non-Reentrant check protected.
            _reward(employees[i], rewards[i]);

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function rewardEmployeesWithToken(
        address[] calldata employees,
        uint256[] calldata rewards,
        address token
    ) external onlyOwner nonReentrant returns (bool) {
        if (token == address (0)) revert ZeroAddress();
        if (employees.length != rewards.length) revert RecipientRewardsMismatch();
        uint256 sum = _getSum(rewards);

        if (sum > IERC20(token).balanceOf(address(this))) revert InsufficientFunds();

        for (uint256 i; i < employees.length; ) {
            /// @dev Non-Reentrant check protected.
            if (employees[i] != address(0)) {
                IERC20(token).safeTransfer(employees[i], rewards[i]);

                emit RewardToken(employees[i], token, rewards[i]);
            }

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function rewardContractorWithETH(
        address contractor,
        uint256 reward
    ) external onlyOwner nonReentrant returns (bool) {
        if (contractor == address(0)) revert ZeroAddress();
        if (reward > address(this).balance) revert InsufficientFunds();

        (bool success, ) = payable(contractor).call{value: reward}("");
        require(success, "Wyre: Call to external address failed!");

        emit RewardETH(contractor, reward);
        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function rewardContractorWithToken(
        address contractor,
        uint256 reward,
        address token
    ) external onlyOwner nonReentrant returns (bool) {
        if (token == address(0)) revert ZeroAddress();
        if (contractor == address(0)) revert ZeroAddress();
        if (reward > IERC20(token).balanceOf(address(this))) revert InsufficientFunds();

        IERC20(token).safeTransfer(contractor, reward);

        emit RewardToken(contractor, token, reward);
        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function hashContractorETHRewardForSigning(
        address contractor,
        uint256 reward,
        uint256 seed,
        uint256 deadline
    ) external view onlyOwner returns (bytes32) {
        if (contractor == address(0)) revert ZeroAddress();
        if (deadline <= block.timestamp) revert PastTime();
        return _getHash(contractor, reward, address(0), seed, deadline);
    }

    /**
    * @inheritdoc IWyre
    */
    function hashContractorTokenRewardForSigning(
        address contractor,
        uint256 reward,
        address token,
        uint256 seed,
        uint256 deadline
    ) external view onlyOwner returns (bytes32) {
        if (contractor == address(0)) revert ZeroAddress();
        if (deadline <= block.timestamp) revert PastTime();
        return _getHash(contractor, reward, token, seed, deadline);
    }

    /**
    * @inheritdoc IWyre
    */
    function executeSignedContractorETHReward(
        address contractor,
        uint256 reward,
        uint256 seed,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOwner nonReentrant returns (bool) {
        bytes32 msgHash = _getHash(contractor, reward, address(0), seed, deadline);

        if (usedRSignatures[r]) revert UsedSignature();

        address recovered = msgHash.recover(v, r, s);

        if (recovered != owner()) revert CallByNonAdmin();
        if (reward > address(this).balance) revert InsufficientFunds();

        (bool success, ) = payable(contractor).call{value: reward}("");
        require(success, "Wyre: Call to external address failed!");

        usedRSignatures[r] = true;
        emit RewardETH(contractor, reward);
        return true;
    }

    /**
    * @inheritdoc IWyre
    */
    function executeSignedContractorTokenReward(
        address contractor,
        uint256 reward,
        address token,
        uint256 seed,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOwner nonReentrant returns (bool) {
        bytes32 msgHash = _getHash(contractor, reward, token, seed, deadline);

        if (usedRSignatures[r]) revert UsedSignature();

        address recovered = msgHash.recover(v, r, s);

        if (recovered != owner()) revert CallByNonAdmin();
        if (reward > IERC20(token).balanceOf(address(this))) revert InsufficientFunds();

        IERC20(token).safeTransfer(contractor, reward);

        usedRSignatures[r] = true;
        emit RewardToken(contractor, token, reward);
        return true;
    }

    function _getSum(uint256[] memory _rewards) private pure returns (uint256) {
        uint256 _sum;

        for (uint256 i; i < _rewards.length; ) {
            _sum += _rewards[i];

            unchecked {
                ++i;
            }
        }

        return _sum;
    }

    function _reward(address _addr, uint256 _rewardValue) private {
        if (_addr != address(0)) {
            (bool success, ) = payable(_addr).call{value: _rewardValue}("");
            require(success, "Wyre: Call to external address failed!");
            /// @notice success evaluates to false on two conditions:
            ///         1. If the receiving address is a contract and has no receive() function.
            ///         2. If the callback function on the receiving address reverts.

            emit RewardETH(_addr, _rewardValue);
        }
    }

    function _getHash(
        address contractor,
        uint256 reward,
        address token,
        uint256 seed,
        uint256 deadline
    ) private pure returns (bytes32) {
        if (contractor == address(0)) revert ZeroAddress();

        return keccak256(
            abi.encode(
                abi.encodePacked(
                    MESSAGE_HASH
                ),
                DOMAIN_SEPARATOR,
                contractor,
                reward,
                token,
                seed,
                deadline
            )
        );
    }
}