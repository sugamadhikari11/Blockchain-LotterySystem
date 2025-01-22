// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address public owner;
    address[] public players;
    address public winner;
    uint256 public minimumEntryAmount; // Minimum amount required to enter the lottery

    constructor() {
        owner = msg.sender; // Set the contract deployer as the owner
        minimumEntryAmount = 0.1 ether; // Set the minimum ether required to enter
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier hasEnoughEther() {
        require(address(this).balance > 0, "Insufficient funds in the contract to draw a winner");
        _;
    }

    // Function to enter the lottery
    function enterLottery() external payable {
        require(msg.value >= minimumEntryAmount, "Minimum 0.1 ETH required to enter");

        players.push(msg.sender); // Add the player to the players list
    }

    // Function to draw the winner
    function drawWinner() external onlyOwner hasEnoughEther {
        require(players.length > 0, "No players in the lottery");

        // Select a random player from the list
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % players.length;
        winner = players[randomIndex]; // Set the winner address

        // Reset the players list
        players = new address[](0);       // Transfer the prize (contract balance) to the winner
        payable(winner).transfer(address(this).balance);

        // Emit an event for the winner
        emit LotteryWinner(winner, address(this).balance);
    }

    // Function to get the current number of players
    function getPlayers() external view returns (address[] memory) {
        return players; // Return the list of players
    }

    // Function to get the winner address
    function getWinner() external view returns (address) {
        return winner; // Return the winner address
    }

    // Event to notify when a winner is drawn
    event LotteryWinner(address winner, uint256 prizeAmount);
}
