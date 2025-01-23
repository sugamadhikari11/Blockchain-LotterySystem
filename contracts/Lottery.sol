// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    struct Room {
        address owner;
        address[] players;
        address winner;
        uint256 totalBalance;
        address[] previousWinners;
        bool isActive;
        mapping(address => bool) hasEntered; // Track if an address has entered the lottery
    }

    mapping(uint256 => Room) public rooms; // Mapping of room ID to Room
    uint256 public roomCount; // Counter for room IDs
    uint256 public minimumEntryAmount; // Minimum amount required to enter the lottery

    constructor() {
        minimumEntryAmount = 0.1 ether; // Set the minimum ether required to enter
    }

    modifier onlyOwner(uint256 roomId) {
        require(msg.sender == rooms[roomId].owner, "You are not the owner of this room");
        _;
    }

    modifier roomActive(uint256 roomId) {
        require(rooms[roomId].isActive, "Room is not active");
        _;
    }

    modifier roomInactive(uint256 roomId) {
        require(!rooms[roomId].isActive, "Room is already active");
        _;
    }

    // Function to create a new lottery room
    function createRoom() external {
        roomCount++;
        Room storage newRoom = rooms[roomCount]; // Create a reference to the new room
        newRoom.owner = msg.sender; // Set the owner
        newRoom.players = new address[](0); // Initialize players array
        newRoom.winner = address(0); // Initialize winner
        newRoom.totalBalance = 0; // Initialize total balance
        newRoom.previousWinners = new address[](0); // Initialize previous winners array
        newRoom.isActive = false; // Set the room as inactive
    }

    // Function to start the lottery in a room
    function startLottery(uint256 roomId) external onlyOwner(roomId) roomInactive(roomId) {
        rooms[roomId].isActive = true; // Set the room as active
    }

    // Function to end the lottery in a room
    function endLottery(uint256 roomId) external onlyOwner(roomId) roomActive(roomId) {
        require(rooms[roomId].players.length > 0, "No players in the room");

        // Select a random player from the list
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % rooms[roomId].players.length;
        rooms[roomId].winner = rooms[roomId].players[randomIndex]; // Set the winner address

        // Transfer the prize (total balance) to the winner
        payable(rooms[roomId].winner).transfer(rooms[roomId].totalBalance);

        // Store the winner in the previous winners list
        rooms[roomId].previousWinners.push(rooms[roomId].winner);

        // Reset the players list and total balance
        rooms[roomId].players = new address[](0);
        rooms[roomId].totalBalance = 0;
        rooms[roomId].isActive = false; // Set the room as inactive
    }

    // Function to enter the lottery in a room
    function enterLottery(uint256 roomId) external payable roomActive(roomId) {
        require(msg.value >= minimumEntryAmount, "Minimum 0.1 ETH required to enter");
        require(!rooms[roomId].hasEntered[msg.sender], "You have already entered the lottery");

        rooms[roomId].players.push(msg.sender); // Add the player to the players list
        rooms[roomId].totalBalance += msg.value; // Update the total balance
        rooms[roomId].hasEntered[msg.sender] = true; // Mark the player as having entered
    }

    // Function to get the current players in a room
    function getPlayers(uint256 roomId) external view returns (address[] memory) {
        return rooms[roomId].players; // Return the list of players
    }

    // Function to get the winner address in a room
    function getWinner(uint256 roomId) external view returns (address) {
        return rooms[roomId].winner; // Return the winner address
    }

    // Function to get previous winners in a room
    function getPreviousWinners(uint256 roomId) external view returns (address[] memory) {
        return rooms[roomId].previousWinners; // Return the list of previous winners
    }

    // Function to get the total balance of the room
    function getTotalBalance(uint256 roomId) external view returns (uint256) {
        return rooms[roomId].totalBalance; // Return the total balance of the room
    }

    // Function to check if a room is active
    function isRoomActive(uint256 roomId) external view returns (bool) {
        return rooms[roomId].isActive; // Return the active status of the room
    }
}
