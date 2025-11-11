// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 1. **Varijable stanja:**
//     - `address public owner` – adresa vlasnika (onaj koji je deployao ugovor)
//     - `uint public goal` – cilj prikupljanja u wei
//     - `uint public deadline` – vrijeme do kojeg traje kampanja
//     - `uint public totalRaised` – ukupno prikupljeni iznos
//     - `bool public goalReached` i `bool public fundsWithdrawn` – status kampanje
// 2. **Funkcionalnosti:**
//     - `constructor(uint _goal, uint _durationMinutes)` – postavlja vlasnika, cilj (u etherima) i trajanje kampanje
//     - `donate()` – `payable` funkcija za uplate; bilježi uplatitelja i iznos, povećava `totalRaised`
//     - `withdrawFunds()` – omogućuje **vlasniku** da povuče sredstva **ako je cilj postignut** i kampanja završila
//     - `refund()` – omogućuje korisnicima povrat uplaćenih sredstava ako **kampanja nije uspjela**
//     - `getBalance()` – vraća trenutačni balans ugovora
//     - `getTimeLeft()` – prikazuje koliko sekundi je ostalo do kraja kampanje
// 3. **Dodatno:**
//     - Koristite `require` provjere gdje je potrebno (npr. za autorizaciju i vremenske uvjete).
//     - Emitirajte `event`e za donaciju, povlačenje sredstava i refundiranje.
//     - Koristite `modifier`e za provjeru vlasništva i status kampanje.

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

    constructor(uint _goal, uint _durationMinutes) {
        require(_durationMinutes > 0);
        goal = _goal;
        deadline = block.timestamp + (_durationMinutes * 60);
        owner = msg.sender;
    }

    function donate(address sender, uint amount) payable public {
        if (sender.balance < amount) revert("Insufficient balance");
        if (block.timestamp > deadline) revert("Campaign has ended");

        totalRaised += amount;
        goalReached = totalRaised >= goal;
        donations[msg.sender] += amount;
        emit DonationReceived(sender, amount);
    }

    function withdrawFunds() public onlyOwner notWithdrawn {
        require(goalReached && block.timestamp > deadline);

        payable(msg.sender).transfer(totalRaised);
        fundsWithdrawn = true;

        emit FundsWithdrawn(msg.sender, totalRaised);
    }

    function refund() payable public {
        require(!goalReached);
        require(block.timestamp > deadline);

        uint amount = donations[msg.sender];
        require(amount > 0, "No donation to refund");

        donations[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit RefundMade(msg.sender, amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTimeLeft() public view returns (uint) {
        if (block.timestamp > deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }
}