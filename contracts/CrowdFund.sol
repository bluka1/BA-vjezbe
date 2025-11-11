// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFund {
    address public owner;
    uint public goal;
    uint public deadline;
    uint public totalRaised;
    bool public goalReached;
    bool public fundsWithdrawn;
    mapping(address => uint) public donations;

    event DonationReceived(address donor, uint amount);
    event FundsWithdrawn(address owner, uint amount);
    event RefundMade(address receiver, uint amount);

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner of this contract.");
        _;
    }

    modifier notWithdrawn {
        require(!fundsWithdrawn);
        _;
    }

    modifier campaignNotEnded {
        require(block.timestamp < deadline);
        _;
    }

    constructor(uint _goal, uint _durationMinutes) {
        require(_durationMinutes > 0);
        goal = _goal;
        deadline = block.timestamp + (_durationMinutes * 60);
        owner = msg.sender;
    }

    function donate(uint amount) payable public campaignNotEnded {
        if (address(msg.sender).balance < amount) revert("Insufficient balance");

        totalRaised += amount;
        goalReached = totalRaised >= goal;
        donations[msg.sender] += amount;
        emit DonationReceived(msg.sender, amount);
    }

    function withdrawFunds() public payable onlyOwner notWithdrawn campaignNotEnded {
        require(goalReached);

        payable(msg.sender).transfer(totalRaised);
        fundsWithdrawn = true;

        emit FundsWithdrawn(msg.sender, totalRaised);
    }

    function refund() payable public campaignNotEnded {
        require(!goalReached);

        uint amount = donations[msg.sender];
        require(amount > 0, "No donation to refund");

        donations[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit RefundMade(msg.sender, amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTimeLeft() public view campaignNotEnded returns (uint) {
        return deadline - block.timestamp;
    }
}