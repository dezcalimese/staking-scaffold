# Scaffold-eth Staking Dapp

## Project Description
- This is a staking decentralized app allowing a single user to deposit and withdraw from the `Staker` contract, which has an interest payout rate of 0.1 ETH for every second that the deposited ETH is eligible for interest accrument

## Simple Workflow
- User able to deposit funds after deadline passes 
- Deposited ETH accrues interest between dealine to deposit and withdraw
- After withdrawl deadline has passed, user is able to withdraw entire principal balance as well as accrued interest until another deadline hits
- After additional window for withdrawl has passed, user is essentially timed out from withdrawing their funds
- If funds are left in the staking contract, they are locked in an external contract

## How to Run a Local Project
- Open up a terminal in the root folder, run `yarn start`
- In another terminal, run `yarn chain`
- In a third terminal, run `yarn deploy`