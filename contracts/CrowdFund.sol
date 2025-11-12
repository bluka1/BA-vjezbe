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
    Campaign[] public campaigns;

    struct Campaign {
        string name;
        uint goal;
        uint deadline;
        uint totalRaised;
        mapping(address => uint) donations;
    }

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
        require(block.timestamp >= deadline, "Campaign has ended.");
        _;
    }

    constructor(uint _goal, uint _durationMinutes) {
        require(_durationMinutes > 0);
        goal = _goal * 1e18;
        deadline = block.timestamp + (_durationMinutes * 60);
        owner = msg.sender;
    }

    function createCampaign(string memory _title, uint _goal, uint _durationMinutes) public {
        campaigns.push();
        Campaign storage c = campaigns[campaigns.length - 1];
        c.name = _title;
        c.goal = _goal * 1e18;
        c.totalRaised = 0;
        c.deadline = block.timestamp + (_durationMinutes * 1 minutes);
    }

    function donateTo(uint campaignId) payable public {
        Campaign storage c = campaigns[campaignId];
        c.donations[msg.sender] += msg.value;
        c.totalRaised += msg.value;
    }

    function getBalanceForCampaign(uint cId) public view returns (uint) {
        return campaigns[cId].totalRaised;
    }

    function donate() payable public campaignNotEnded {
        require(msg.value > 0, "Amount must be greater than 0");

        totalRaised += msg.value;
        donations[msg.sender] += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawFunds() public payable onlyOwner notWithdrawn campaignEnded {
        goalReached = address(this).balance >= goal;
        require(goalReached);

        payable(owner).transfer(address(this).balance);
        fundsWithdrawn = true;

        emit FundsWithdrawn(msg.sender, totalRaised);
    }

    function refund() payable public campaignEnded {
        bool goalNotReached = address(this).balance <= goal;
        require(goalNotReached, "Campaign goal not reached");

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