# Nebula DTF — External Dependencies

Everything outside our own code. **You asked to be told about these before we start coding.**
Legend: ✅ ready / no action · 🔧 install or wire up (routine) · 🚧 **blocker — confirm before the stage that needs it** · 📅 long-lead (start early).

---

## Phase 1 — needed to mint the DTF token against on-chain collateral

| # | Dependency | Type | Status | Cost | Action needed |
|---|---|---|---|---|---|
| 1 | **Reflector oracle asset coverage** | Oracle | ✅ partial | Free to read | **Resolved 2026-07-05 (screenshot):** testnet Pulse oracle `CAVLP5DH2GJPZMVO7IJY4CVOD5MWEFTJFVPD2YY2FQXOQHRGHK4D6HLP` mirrors pubnet — AQUA + EURC confirmed, 14 decimals, 5-min sampling. **VELO not sighted in feed list — verify before the mainnet basket is final.** |
| 2 | **Testnet asset availability** | Assets | ✅ | Free | **Resolved:** self-issued `TAQUA/TVELO/TUSDC/TEURC` classic assets + SACs (ADR-012), via `scripts/setup-testnet.ps1`. XLM = real native. |
| 3 | **Launchtube access token** | Infra/API | 🚧 | Free (request) | Required for sponsored-fee UX (Stage 1.5). Request early — issuance may take days. Not blocking Week 1 contracts. |
| 4 | Rust + Stellar CLI toolchain | Tooling | ✅ | Free | Rust 1.96.1, Stellar CLI 27.0.0 (winget, `C:\Program Files (x86)\Stellar CLI`), `wasm32v1-none`. |
| 5 | OpenZeppelin `stellar-tokens` crate | Cargo dep | ✅ | Free | Pinned 0.7.2 (soroban-sdk 26.1). Audited. Share token + (Phase 3) AllowList. |
| 6 | ~~`sep-40-oracle` crate~~ | Cargo dep | ✅ dropped | — | Conflicts with OZ (needs sdk ^25 vs ^26). Replaced by ~40-line hand-rolled interface in `crates/nebula-interfaces` (ADR-009). |
| 7 | DIA oracle (Soroban) | Oracle | 🔧 | Free to read | Secondary price source; get its contract address on testnet. |
| 8 | SAC contract IDs for each asset | Config | 🔧 | Free | Derive/record SAC IDs per network for the basket assets. |
| 9 | Testnet accounts (friendbot) | Accounts | ✅ | Free | Create deploy + test identities. |
| 10 | **Mainnet XLM for deploy + seed** | Funds | 📅 | Real XLM | Rise In sponsors mainnet per PRD — **confirm the sponsorship mechanism and amount** before Stage 1.7. |
| 11 | PasskeyKit smart-wallet setup | Frontend | 🔧 | Free | Deploy/configure for passkey onboarding (Stage 1.5). |
| 12 | Horizon + Soroban RPC endpoints | Infra | ✅ | Free (public) | Public endpoints fine; self-host only if rate-limited. |
| 13 | Deploy key management | Security | 🔧 | — | Multisig for mainnet admin (ADR-007). Decide signer set before mainnet. |

## Phase 2 — cross-chain

| # | Dependency | Type | Status | Notes |
|---|---|---|---|---|
| 14 | Axelar ITS contracts (Gateway, TokenManager, GasService, ITS) | Bridge | 🔧 | Record addresses on Stellar + source chains; use as shipped (ADR-008). |
| 15 | EVM-side test setup (Ethereum testnet + funds) | Testing | 🔧 | To test inbound ETH→Stellar flow. |
| 16 | Allbridge Core contracts/API | Bridge | 🔧 | Native USDC inflow. |
| 17 | Soroswap API key + SDK | Swap | 🔧 | Single-asset deposit routing; `out_min` per leg. |

## Phase 3 — regulated assets

| # | Dependency | Type | Status | Notes |
|---|---|---|---|---|
| 18 | Franklin Templeton institutional KYC / allowlist (BENJI) **or** MoonPay Trade institutional account | Partnership | 📅 | Long lead. No permissionless path to BENJI. |
| 19 | Securities-law counsel (fund-of-funds structuring / geofencing) | Legal | 📅 | Required before any regulated-asset Folio launches. |
| 20 | DTCC tokenized-asset availability on Stellar | External | 📅 | H1 2027 per DTCC timeline. Out of our control. |

---

## Bottom line before we code Phase 1
Nothing blocks starting the **contracts** (deps 4–9 are routine). The three real gates are
**🚧-1 (does Reflector price our assets?)** and **🚧-2 (mock tokens on testnet?)** — both
answerable in an hour of verification — and **🚧-3 (Launchtube token)** which only matters at
Stage 1.5. Confirm 1 and 2 and we can begin Stage 1.0 immediately.
```
