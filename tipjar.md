# Level 1 — Ship a TipJar

Write a `TipJar` smart contract, deploy it to a live testnet, and prove it
works. This is the required level.

## Build

A `TipJar` contract in Solidity:

- Anyone can `deposit()` ETH (payable). Track the running total tipped **per
  address**, so repeat deposits from the same address accumulate rather than
  overwrite.
- Expose `totalTipped(address)` and a contract-wide `totalReceived()`.
- Only the owner can `withdraw()` the full balance to themselves.
- Emit a `Tipped(address indexed from, uint256 amount, uint256 newTotal)` event
  on every deposit.
- Reject zero-value deposits with a `require`.

Constraints:

- Use **OpenZeppelin Contracts v5** for `Ownable`. In v5 `Ownable` takes a
  constructor argument (`Ownable(msg.sender)`).
- Solidity `^0.8.20` or newer.

## Deploy

- Deploy to the **Sepolia** testnet (grab test ETH from a Sepolia faucet).
- **Verify** the contract source on Sepolia Etherscan so the code is readable.
- Send at least two deposits from the same address and one `withdraw()` so there
  is real activity on-chain.

## Submit

Submit on the Challenges page:

1. Your name / email.
2. Deployed contract address (Sepolia).
3. Etherscan link to the verified contract.
4. Link to your deploy transaction.
5. Repo link (contract + deploy script; Foundry or Hardhat, your choice).
6. A short note on how you tested it and any decision you had to make along the
   way.

## A note on AI

AI use is encouraged. But you must understand what you are doing and what is
happening: be able to explain every line, why you made each decision, and how
you verified it actually works. The tool is a collaborator, not a substitute for
understanding, and the writeup is where that understanding shows.

yes I used ai to make this doc lol