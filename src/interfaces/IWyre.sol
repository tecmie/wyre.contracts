// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

/**
* @title IWyre - Wyre Interface.
* @author Tecmie Labs.
* @notice Version: v0.0.1.
* @dev  With the outlook on creating an onchain payroll system,
*       this interface is designed to control `all` the functions listed in
*       the Wyre contract.
*       The goal is to create, as stated earlier, an onchain payroll system where
*       payments in ETH or any specified ERC20 token is distributed to one or specified
*       address(es), (including contracts), of which can be either an employee or a contractor
*       in a pull over push method, or is hashed using the EIP-712 standard, signed offchain
*       and then executed onchain at a later date.
*       Payments and fund distribution are initiated by a central point, the Admin (owner/deployer).
*/

interface IWyre {
    /// @dev Emitted if calls are made by non admin or owner.
    error CallByNonAdmin();
    /// @dev Emitted if the reward to be sent is more than contract balance.
    error InsufficientFunds();
    /// @dev Emitted if deadline is passed.
    error PastTime();
    /// @dev Emitted if recipient count isn't equal to rewards count.
    error RecipientRewardsMismatch();
    /// @dev Emitted if a signature is already used.
    error UsedSignature();
    /// @dev Emitted if rewards are to be sent to a zero address.
    error ZeroAddress();

    event Fund(uint256 amount);
    event FundToken(address token, uint256 amount);
    event RewardETH(address indexed employee, uint256 indexed reward);
    event RewardToken(address indexed employee, address token, uint256 indexed reward);

    /// @dev Sends Ether to the contract.
    /// @return bool Funding status.
    function fundContractWithETH() external payable returns (bool);

    /**
    * @dev Transfers a specified `amount` of ERC20 tokens to the contract.
    * @notice   Some tokens do not conform with the IERC20 standards and
    *           must be checked for the presence of `transferFrom()` to avoid function reverts.
    *           OpenZeppelin's SafeERC20 will be utilized within this function.
    * @param token  IERC20 token.
    * @param amount Amount to be transferred.
    * @return bool Funding status.
    */
    function fundContractWithToken(address token, uint256 amount) external returns (bool);

    /**
    * @dev Distributes ETH `rewards` to a list of `employees` from the contract's balance.
    * @notice Require employees.length == rewards.length.
    * @param employees  Array of employees to receive ETH.
    * @param rewards    Array of rewards corresponding to each employee in employees.
    * @return bool Reward status.
    */
    function rewardEmployeesWithETH(
        address[] calldata employees,
        uint256[] calldata rewards
    ) external returns (bool);

    /**
    * @dev  Transfers respective set of `rewards` amounts of a particular ERC20 token
    *       to a list of `employees` from the contract's token balance.
    * @notice Require employees.length == rewards.length.
    * @param employees  Array of employees to receive token.
    * @param rewards    Array of token rewards corresponding to
    *                   each employee in employees.
    * @param token      IERC20 token to be disbursed.
    * @return bool Reward status.
    */
    function rewardEmployeesWithToken(
        address[] calldata employees,
        uint256[] calldata rewards,
        address token
    ) external returns (bool);

    /**
    * @dev  Transfers `reward` amount of ETH to a specified `contractor` address
    *       from the contract's balance.
    * @param contractor Address of contractor to receive ETH.
    * @param reward     Contractor payment.
    * @return bool Reward status.
    */
    function rewardContractorWithETH(
        address contractor,
        uint256 reward
    ) external returns (bool);

    /**
    * @dev  Transfers `reward` amount of a specified IERC20 token to a specified contractor
    *       from the contract's balance.
    * @param contractor Address of contractor to receive ETH.
    * @param reward     Contractor payment.
    * @param token      IERC20 token to be disbursed.
    * @return bool Reward status.
    */
    function rewardContractorWithToken(
        address contractor,
        uint256 reward,
        address token
    ) external returns (bool);

    /**
    * @dev  Generates a hash for off-chain signing using set
    *       variables for future contractor payment in ETH,
    *       using a randomly generated seed.
    * @param contractor Address of contractor to receive ETH.
    * @param reward     Contractor payment.
    * @param seed       Randomly generated large uint256 value.
    * @param deadline   Any future date.
    * @return bytes32 hash.
    */
    function hashContractorETHRewardForSigning(
        address contractor,
        uint256 reward,
        uint256 seed,
        uint256 deadline
    ) external view returns (bytes32);

    /**
    * @dev  Generates a hash for off-chain signing using set
    *       variables for future contractor payment in a specified Token,
    *       using a randomly generated seed.
    * @param contractor Address of contractor to receive token.
    * @param reward     Contractor payment.
    * @param token      IERC20 token to be disbursed.
    * @param seed       Randomly generated large uint256 value.
    * @param deadline   Any future date.
    * @return bytes32 hash.
    */
    function hashContractorTokenRewardForSigning(
        address contractor,
        uint256 reward,
        address token,
        uint256 seed,
        uint256 deadline
    ) external view returns (bytes32);

    /**
    * @dev  Executes a particular transaction using the previously
    *       generated hash for ETH and its corresponding signature.
    * @param contractor Address of contractor to receive ETH.
    * @param reward     Contractor payment..
    * @param seed       Randomly generated large uint256 value.
    * @param deadline   Any future date.
    * @param v        Off-chain signature part.
    * @param r        Off-chain signature part.
    * @param s        Off-chain signature part.
    * @return bool Reward status.
    */
    function executeSignedContractorETHReward(
        address contractor,
        uint256 reward,
        uint256 seed,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
    * @dev  Executes a particular transaction using the previously
    *       generated hash for a specified token and its corresponding signature.
    * @param contractor Address of contractor to receive ETH.
    * @param reward     Contractor payment.
    * @param token      IERC20 token to be disbursed..
    * @param seed       Randomly generated large uint256 value.
    * @param deadline   Any future date.
    * @param v        Off-chain signature part.
    * @param r        Off-chain signature part.
    * @param s        Off-chain signature part.
    * @return bool Reward status.
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
    ) external returns (bool);
}