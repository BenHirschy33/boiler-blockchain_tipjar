# Boiler Blockchain — Level 1: Ship a TipJar

A production-grade, verified smart contract repository built with **Foundry** for the Purdue Boiler Blockchain Developer Team Assessment (Level 1: Ship a TipJar).

---

## 📌 Submission Overview & On-Chain Verification

| Item | Details |
| :--- | :--- |
| **Contract Name** | `TipJar` |
| **Network** | Ethereum Sepolia Testnet (Chain ID: `11155111`) |
| **Deployed Address** | [`0x85B353268b761d51f43C9b22Af7d05a9305C9775`](https://sepolia.etherscan.io/address/0x85b353268b761d51f43c9b22af7d05a9305c9775#code) |
| **Deploy Transaction** | [`0xdcb307ebb0a019cc9ee1e7fb234356c5ecb32b3db978f995b672a43d43f7ec0c`](https://sepolia.etherscan.io/tx/0xdcb307ebb0a019cc9ee1e7fb234356c5ecb32b3db978f995b672a43d43f7ec0c) |
| **Contract Owner** | `0x8f5190426dae297a29C298A0fA4F04FFeda29541` |
| **Verification Status** | **Verified with Green Checkmark** on Etherscan and Sourcify |
| **On-Chain Activity Proof** | Two deposits (0.001 ETH, 0.002 ETH) + One full owner withdrawal executed live on Sepolia |

---

## 🏗️ Architecture & Technical Decisions

### 1. State Storage & Gas Complexity
- **Per-Address Tracking (`mapping(address => uint256) public totalTipped`)**:
  - Uses Solidity's native hash map rather than an array of structs.
  - Value locations are computed as $\text{keccak256}(\text{abi.encode}(\text{key}, \text{slot}))$, providing $O(1)$ constant-time reads and writes with zero lookup loops.
  - Accumulates balances across multiple deposits from the same address rather than overwriting.
- **Contract-Wide Metric (`uint256 public totalReceived`)**:
  - Deliberately decoupled from `address(this).balance`. 
  - While `address(this).balance` reflects temporary contract liquidity (and resets to `0` upon owner withdrawal), `totalReceived` serves as a permanent historical ledger of all-time ETH volume processed by the contract.
- **Automatic Getters**:
  - Declaring both state variables as `public` causes the compiler to generate external `view` getter functions (`totalTipped(address)` and `totalReceived()`) automatically, reducing bytecode overhead.

### 2. Access Control: OpenZeppelin Contracts v5
- Inherits from OpenZeppelin Contracts v5 (`@openzeppelin/contracts/access/Ownable.sol`).
- Unlike OpenZeppelin v4 (which implicitly defaulted owner to `_msgSender()`), OpenZeppelin v5 requires explicit constructor initialization:
  ```solidity
  constructor() Ownable(msg.sender) {}
  ```
- Protects deployments against ambiguous ownership when deploying via factories or deployment proxies.
- Uses gas-efficient custom errors (`error OwnableUnauthorizedAccount(address account)`) instead of string reverts.

### 3. Native Ether Transfers: `.call` vs. `.transfer`
- In `withdraw()`, funds are transferred using low-level call syntax:
  ```solidity
  (bool success, ) = payable(owner()).call{value: balance}("");
  require(success, "TipJar: Withdrawal failed");
  ```
- **Rationale**: The legacy `.transfer()` method forwards a rigid 2,300 gas stipend. If the `owner` is a multisig (e.g., Safe), proxy, or smart contract wallet, receiving ETH consumes more than 2,300 gas, causing `.transfer()` to revert and permanently locking funds. Using `.call` forwards available gas safely and checks the returned boolean.

### 4. Event Architecture & Topic Indexing
- Emits `Tipped(address indexed from, uint256 amount, uint256 newTotal)` upon every deposit:
  - `from` is `indexed` into **Topic 1** of the EVM log bloom filter, allowing off-chain indexers (Etherscan, The Graph) to query transactions per tipper address in $O(1)$ time.
  - `amount` and `newTotal` are stored in the unindexed **Data** payload to minimize event logging gas.

---

## 🧪 Testing Suite (Foundry)

The contract is thoroughly tested using Foundry (`forge-std`), with 11 automated tests covering happy paths, edge cases, reverts, custom errors, event emission, and property-based fuzzing.

```bash
Ran 11 tests for test/TipJar.t.sol:TipJarTest
[PASS] testFuzz_Deposit(uint96) (runs: 256, μ: 103285, ~: 103285)
[PASS] test_DepositDifferentUsers() (gas: 172811)
[PASS] test_DepositOnce() (gas: 101544)
[PASS] test_DepositTwice() (gas: 143342)
[PASS] test_EmitTippedEvent() (gas: 88650)
[PASS] test_EmptyWithdraw() (gas: 34761)
[PASS] test_InitialState() (gas: 22706)
[PASS] test_NonOwnerWithdraw() (gas: 113224)
[PASS] test_OwnerWithdraw() (gas: 134848)
[PASS] test_Submission() (gas: 195478)
[PASS] test_ZeroDeposit() (gas: 32504)
Suite result: ok. 11 passed; 0 failed; 0 skipped
```

### Test Coverage Highlights
1. **Accumulation**: `test_DepositTwice` verifies that multiple deposits from the same address accumulate rather than overwrite.
2. **User Isolation**: `test_DepositDifferentUsers` proves that deposits from `user1` do not affect `user2`'s tipped total.
3. **Zero Deposit Revert**: `test_ZeroDeposit` asserts that `require(msg.value > 0)` reverts zero-value transactions.
4. **Access Control**: `test_NonOwnerWithdraw` uses `abi.encodeWithSelector` to assert that unauthorized callers are rejected with OpenZeppelin's `OwnableUnauthorizedAccount` custom error.
5. **Zero Balance Revert**: `test_EmptyWithdraw` asserts that attempting to withdraw an empty balance reverts.
6. **Event Verification**: `test_EmitTippedEvent` uses `vm.expectEmit` to assert that Topic 1 (`from`), Data (`amount`, `newTotal`), and emitter address match exactly.
7. **Property-Based Fuzzing**: `testFuzz_Deposit` executes 256 randomized runs with pseudorandom amounts to mathematically prove boundary safety.
8. **End-to-End Submission Flow**: `test_Submission` simulates the exact required live sequence (2 deposits from one wallet, followed by full owner withdrawal).

---

## 🛠️ Local Development & Commands

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`)

### 1. Clone & Install Submodules
```bash
git clone --recurse-submodules https://github.com/BenHirschy33/boiler-blockchain_tipjar.git
cd boiler-blockchain_tipjar
```

### 2. Compile Contracts
```bash
forge build
```

### 3. Run Test Suite
```bash
forge test -vvv
```

### 4. Gas Snapshot
```bash
forge snapshot
```

### 5. Format Code
```bash
forge fmt --check
```

---

## 🚀 Deployment & Verification Script

The contract was deployed using Foundry's native Solidity scripting system:

```bash
forge script script/TipJar.s.sol:DeployTipJar \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --interactive
```

The script execution receipt is preserved in `broadcast/TipJar.s.sol/11155111/run-latest.json` for on-chain auditability.

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
