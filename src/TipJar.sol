// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TipJar is Ownable {
    // Maps each user address to their cumulative tipped amount in wei
    mapping(address => uint256) public totalTipped;

    // Cumulative historical ETH received across all tips (in wei)
    uint256 public totalReceived;

    /// @notice Emitted whenever an address tips ETH to the contract
    /// @param from The address that sent the tip
    /// @param amount The amount of ETH sent in this deposit (in wei)
    /// @param newTotal The new cumulative total tipped by this address
    event Tipped(address indexed from, uint256 amount, uint256 newTotal);

    /// @notice Sets the deployer as the initial owner via OpenZeppelin Ownable
    constructor() Ownable(msg.sender) {}

    /// @notice Allows any user to deposit ETH into the contract
    function deposit() public payable {
        // payable updates the account balances for contract (transfers from msg.sender to contract)

        require(msg.value > 0, "TipJar: Cannot deposit zero value");

        // Update Total for sender
        totalTipped[msg.sender] += msg.value;

        // Update total for the contract
        totalReceived += msg.value;

        emit Tipped(msg.sender, msg.value, totalTipped[msg.sender]);
    }

    /// @notice Allows the owner to withdraw the entire balance of the contract
    function withdraw() public onlyOwner {
        // onlyOwner checks if msg.sender is the owner. If not it rejects the transaction.
        // Reverts with 'OwnableUnauthorizedAccount(msg.sender)' if msg.sender is not the owner.

        // Get balance for this address (tipjar)
        uint256 balance = address(this).balance;

        // Check if there is a balance to withdraw
        require(balance > 0, "TipJar: No balance to withdraw");

        // Send the balance to the owner
        // Using .call{value:} instead of .transfer() because .transfer is nto used anymore od to gas limit
        (bool success,) = payable(owner()).call{value: balance}("");
        require(success, "TipJar: Withdrawal failed");
    }
}
