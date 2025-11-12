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

    modifier campaignEnded {
        require(block.timestamp >= deadline);
        _;
    }

    constructor(uint _goal, uint _durationMinutes) {
        require(_durationMinutes > 0);
        goal = _goal;
        deadline = block.timestamp + (_durationMinutes * 60);
        owner = msg.sender;
    }

    function donate() payable public campaignNotEnded {
        require(msg.value > 0, "Amount must be greater than 0");

        totalRaised += msg.value;
        donations[msg.sender] += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawFunds() public payable onlyOwner notWithdrawn campaignEnded {
        goalReached = totalRaised >= goal;
        require(goalReached);

        payable(owner).transfer(address(this).balance);
        fundsWithdrawn = true;

        emit FundsWithdrawn(msg.sender, totalRaised);
    }

    function refund() payable public campaignEnded {
        goalReached = totalRaised >= goal;
        require(!goalReached, "Campaign goal reached");

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