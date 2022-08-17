// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

/**
 * @title A simple staking contract
 * @notice This contract allows a single user to deposit and withdraw from the `Staker` contract,
 *         which has an interest payout rate of 0.1 ETH for every second that the deposited ETH is eligible for interest accrument.
 */

contract Staker {
    /// *** State Variables *** ///

    ExampleExternalContract public exampleExternalContract;

    // How much ETH is deposited into the contract
    mapping(address => uint256) public balances;
    // Time that the deposit happened
    mapping(address => uint256) public depositTimestamps;

    // Sets interest rate for dispersement of ETH on the principal amount staked
    uint256 public constant rewardRatePerBlock = 0.1 ether;
    // Deadlines for staking mechanics to begin/end
    uint256 public withdrawalDeadline = block.timestamp + 120 seconds;
    uint256 public claimDeadline = block.timestamp + 240 seconds;
    // Saving the current block
    uint256 public currentBlock = 0;

    /// *** Events *** ///

    event Stake(address indexed sender, uint256 amount);
    event Received(address, uint);
    event Execute(address indexed sender, uint256 amount);

    /// *** Modifiers *** ///

    // Checking whether withdrawal or claim deadlines are true or false
    modifier withdrawalDeadlineReached(bool requireReached) {
        uint256 timeRemaining = withdrawalTimeLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Withdrawal period is not reached yet");
        } else {
            require(timeRemaining > 0, "Withdrawal period has been reached");
        }
        _;
    }

    modifier claimDeadlineReached(bool requireReached) {
        uint timeRemaining = claimPeriodLeft();
        if (requireReached) {
            require(timeRemaining == 0, "Claim period is not reached yet");
        } else {
            require(timeRemaining > 0, "Claim period has been reached");
        }
        _;
    }

    // Calls on a completed() function from external contract and checks bool value to see if flag has been switched
    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Stake already completed!");
        _;
    }

    /// *** Constructor *** ///

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    /// *** Time Functions *** ///

    // If current times are greater than pre-arranged dealines, return 0 to signify that a "state change" has occured;
    // otherwise return the remaining time before dealine is reached

    function withdrawalTimeLeft() public view returns (uint256) {
        if (block.timestamp >= withdrawalDeadline) {
            return (0);
        } else {
            return (withdrawalDeadline - block.timestamp);
        }
    }

    function claimPeriodLeft() public view returns (uint256) {
        if (block.timestamp >= claimDeadline) {
            return (0);
        } else {
            return (claimDeadline - block.timestamp);
        }
    }

    /// *** Deposit/Withdrawal Functions *** ///

    // Function for user to stake ETH in contract
    function stake()
        public
        payable
        withdrawalDeadlineReached(false)
        claimDeadlineReached(false)
    {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        depositTimestamps[msg.sender] = block.timestamp;
        emit Stake(msg.sender, msg.value);
    }

    // Function for user to remove staked ETH inclusive of both principal balance & any accrued interest
    function withdraw()
        public
        withdrawalDeadlineReached(true)
        claimDeadlineReached(true)
    {
        require(balances[msg.sender] > 0, "You have nothing to withdraw!");
        uint individualBalance = balances[msg.sender];
        uint indBalanceRewards = individualBalance +
            ((block.timestamp - depositTimestamps[msg.sender]) *
                rewardRatePerBlock);
        balances[msg.sender] = 0;

        (bool sent, bytes memory data) = msg.sender.call{
            value: indBalanceRewards
        }("");
        require(sent, "RIP: withdrawal failed :( ");
    }

    /// *** Repudiation *** ///

    // Fuction for user to repatriate funds left in staking contract past defined withdrawal period
    function execute() public claimDeadlineReached(true) notCompleted {
        uint256 contractBalance = address(this).balance;
        exampleExternalContract.complete{value: address(this).balance}();
    }

    // "Killing time" on our local testnet
    function killTime() public {
        currentBlock = block.timestamp;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
