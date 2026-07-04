# Nebula DTF — Implementation Plan & Thesis

**Owner:** Utsav Jana
**Source of truth for scope:** `stellar_dtf_prd.md` (PRD v1.0)
**This doc:** how we actually build it, in order, with real interfaces.
**Companion docs:** [`CHECKLIST.md`](./CHECKLIST.md) · [`DECISION_LOG.md`](./DECISION_LOG.md) · [`EXTERNAL_DEPENDENCIES.md`](./EXTERNAL_DEPENDENCIES.md)

---

## 0. TL;DR (read this if nothing else)

We are building the **basket primitive** for Stellar: a Soroban contract (a "Folio")
that holds N on-chain assets, mints one fungible share token against proportional
deposits, computes live NAV from Reflector, and redeems shares pro-rata. Ship Phase 1
to **mainnet** by 25 July 2026.

The first coding target — literally the next thing we build — is exactly what you asked for:

> the contract that mints the DTF (Folio share) token against on-chain collateral
> (SAC-wrapped assets: XLM, USDC, EURC, and friends).

Cross-chain (Axelar) and BENJI/DTCC are Phase 2 and 3. We design so they *slot in*
without a rewrite, but we do not build them now.

**Before we write code, three external things must be confirmed** (see
[`EXTERNAL_DEPENDENCIES.md`](./EXTERNAL_DEPENDENCIES.md), items marked 🚧):
1. Which basket assets Reflector actually prices on testnet/mainnet (NAV depends on it).
2. Whether AQUA/VELO exist on testnet, or we deploy mock SAC test tokens.
3. A Launchtube access token for the fee-sponsored passkey UX (Week 2, not blocking Week 1).

---

## 1. Thesis — what we are building and why

**The gap.** On Stellar today you cannot hold diversified exposure in one token. DTCC
(post-trade backbone of Wall Street, $114T custodied) picked Stellar as its first public
chain for tokenized securities; BENJI, Circle USDC/EURC, and Treasuries are already native.
No basket/DTF product exists on Stellar. Whoever ships the audited basket primitive *now*
becomes the default portfolio layer when the DTCC asset wave lands in H1 2027.

**The product.** A **Folio** = a Soroban contract that:
- custodies several Stellar assets via SAC (Stellar Asset Contract, the SEP-41 interface);
- mints a **Folio share** token (SEP-41, built on OpenZeppelin's audited fungible base);
- redeems shares pro-rata for the underlying at any time;
- computes NAV on-chain from oracle prices at every mint/redeem.

**The wedge (from category data).** Passive *index* DTFs failed (Index Coop $500M→$52M;
Reserve Index DTFs $1.7M). *Yield* DTFs found PMF fast (Reserve Yield DTFs $200M+). So the
destination is **yield-bearing baskets** anchored by a regulated on-chain yield asset
(BENJI, ~3.5%). Phase 1 ships the crypto-native "Stellar Ecosystem" basket as the wedge;
yield is Phase 1.5 / Phase 3.

**Why the phasing is honest, not lazy:**
- Stellar DEX liquidity is thin (~$23M SDEX). So Phase 1 uses **proportional deposits** —
  no swaps, no slippage — and **static weights** — no rebalancing. We design *around* the
  liquidity we actually have instead of pretending it's deep.
- Bridges are the #1 source of catastrophic loss. So cross-chain is opt-in, segregated, and
  uses **audited Axelar/Allbridge exactly as shipped** — never a custom bridge.
- BENJI/DTCC are allowlist-gated securities. That's a legal/partnership track, not a code
  hack — we architect for per-asset transfer eligibility (OZ AllowList) and defer the rest.

---

## 2. Architecture (grounded in verified 2026 interfaces)

### 2.1 Contract map

```
FolioFactory ──deploys──▶ Folio (one instance per basket)
                            │  embeds ── FolioShare  (SEP-41, OZ fungible base module)
                            │  holds ──  SAC balances (XLM, USDC, EURC, AQUA, VELO…)
                            │  mint(deposits[])  / redeem(shares)
                            │  nav()  ──calls──▶ OracleRouter
                            │  pause() / unpause()  (circuit breaker + admin)
                            ▼
OracleRouter (deployed once, shared by all Folios)
   └─ wraps Reflector (primary) + DIA (secondary) via sep-40-oracle PriceFeedClient
   └─ returns validated USD price or errors on staleness / divergence

ReservePool (Phase 3) ── allowlisted BENJI custody ──▶ allocates to yield Folios
```

### 2.2 Key design decisions (full rationale in `DECISION_LOG.md`)

| # | Decision | Why |
|---|---|---|
| ADR-001 | **One Folio contract embeds its own share token** (OZ `fungible` base module inline), not a separate token contract. | Atomic mint (no cross-contract call to a token contract), fewer moving parts, simpler audit surface. |
| ADR-002 | **Do NOT use OZ Vault (ERC-4626).** Custom multi-asset mint/redeem on the OZ fungible *base*. | Verified: the OZ Vault is **single-asset**. A Folio holds N assets; forcing the vault would fight the primitive. |
| ADR-003 | **Proportional deposit/redeem, no swaps, Phase 1.** | Sidesteps thin DEX liquidity entirely; zero slippage; honest at low TVL. |
| ADR-004 | **Static weights, Phase 1** (basket drifts with price; no rebalancing). | Safe at low TVL; rebalancing needs post-DTCC liquidity. |
| ADR-005 | **OracleRouter is a standalone contract deployed once**, referenced by all Folios. | Single place for staleness/divergence config; deploy price logic once, not per-Folio. |
| ADR-006 | **Immutable Folios + factory versioning.** No upgradeable proxies. | Proxies are the classic audit/exploit surface; a new version = a new deploy users opt into. |
| ADR-007 | **Admin behind multisig; mint/redeem pausable** by admin and by oracle divergence. | Contain oracle failure and operator error without holding user funds hostage. |

### 2.3 Verified build primitives (research done 2026-07-05)

| Need | Primitive | Verified interface |
|---|---|---|
| Share token (SEP-41) | OpenZeppelin `stellar-contracts` `fungible` module | `FungibleToken` + `FungibleBurnable` traits; `mintable` extension; `AllowList`/`BlockList` extensions for Phase 3. Audited (Certora). [docs](https://docs.openzeppelin.com/stellar-contracts/tokens/fungible/fungible) |
| Hold/move underlying assets | SAC via `soroban_sdk::token::TokenClient` | `TokenClient::new(&env, &id)` then `.transfer(from, to, amount)`, `.balance(addr)`. [docs](https://developers.stellar.org/docs/tokens/stellar-asset-contract) |
| Prices + staleness | `sep-40-oracle` crate `PriceFeedClient` (Reflector implements SEP-40) | `lastprice(asset) -> Option<PriceData>`, `PriceData { price: i128, timestamp: u64 }`, plus `decimals()`, `resolution()`, `price(asset, ts)`. [docs.rs](https://docs.rs/sep-40-oracle/) · [Reflector contract](https://github.com/reflector-network/reflector-contract) |
| Fee sponsorship + passkey UX | Launchtube + PasskeyKit | Needs a Launchtube access token (external, request early). [PasskeyKit](https://github.com/kalepail/passkey-kit) |

**NAV formula (on-chain, every mint/redeem):**
`NAV = Σ(asset_balance[i] × oracle_price[i]) / total_share_supply`, all normalized to
oracle `decimals()`. Guard: reject any leg whose `PriceData.timestamp` is older than
`max_staleness_ledgers`; pause if Reflector vs DIA diverge beyond threshold.

---

## 3. Phased plan

### Phase 1 — Stellar-native DTF (the 21-day hackathon build, → mainnet 25 Jul)

**Goal:** on mainnet, a user mints Folio shares by depositing the 5 assets in basket
ratio, sees live NAV, and redeems pro-rata. This is the "mint the DTF token against
on-chain collateral" contract you asked for.

**Stage 1.0 — Foundations (Week 1, D1)**
- Cargo workspace: `contracts/folio`, `contracts/factory`, `contracts/oracle_router`, `contracts/mocks`.
- Soroban toolchain, testnet identities, CI (`cargo test` + `soroban contract build`).
- Import OZ `stellar-contracts` + `sep-40-oracle`. Define shared types (`AssetWeight`, `Deposit`, error enum).

**Stage 1.1 — OracleRouter (Week 1, D2)**
- Wrap `PriceFeedClient::lastprice`; normalize to common decimals; staleness guard.
- Two-source median (Reflector + DIA) with a `single-source-ok` fallback flag; divergence check.
- Unit tests against a mock SEP-40 feed (the crate ships a mock).

**Stage 1.2 — Folio core (Week 1, D3–4)**
- Storage: asset list + target weights, admin, oracle_router addr, paused flag.
- `mint(deposits: Vec<(asset, amount)>)`: validate ratios ≈ weights (within tolerance),
  pull each asset via `TokenClient::transfer`, compute shares from NAV, mint shares (OZ fungible).
- `redeem(shares)`: burn shares, transfer each asset out pro-rata (checks-effects-interactions).
- `nav()` view; `pause()/unpause()`.

**Stage 1.3 — FolioFactory (Week 1, D5)**
- `create_folio(assets, weights, name, symbol)` → deploy + init a Folio; registry of instances.
- Versioned wasm hash (ADR-006).

**Stage 1.4 — Testnet end-to-end (Week 1, D6–7)** — *Jul 11 checkpoint*
- Deploy Factory + OracleRouter + Stellar Ecosystem Folio to **testnet**.
- Scripted mint → NAV → redeem round-trip against real (or mock) SAC assets.

**Stage 1.5 — Frontend + UX (Week 2, D8–12)**
- PasskeyKit onboarding (Face-ID wallet), Launchtube fee sponsorship.
- Folio page: composition donut, live NAV (5s poll via Horizon/RPC), user shares & P&L,
  mint/redeem with an asset-ratio helper.
- DIA as second oracle source; wire the divergence circuit breaker end-to-end.

**Stage 1.6 — Testnet beta (Week 2, D13–14)** — cohort users, friction notes, screenshots.

**Stage 1.7 — Mainnet + hardening (Week 3, D15–19)**
- Deploy Factory + Ecosystem Folio to **mainnet**; verify Reflector feeds on mainnet; seed small real balances.
- Failure-path drills: pause drill, staleness rejection, slippage-free redeem verification.
- Landing page + minimal docs.

**Stage 1.8 — Demo Day (Week 3, D20–21)** — dry run, deck, backup video, live judge mint on mainnet.

**Explicitly cut from Phase 1:** swaps/single-asset deposit, rebalancing, cross-chain,
BENJI, fees, governance. Roadmap slides, not code.

### Phase 2 — Cross-chain baskets (months 1–6)

- **Axelar ITS** for wETH/wBTC/wSOL (lock-and-mint → axl* tokens on Stellar). Use the
  shipped Gateway / TokenManager / GasService / InterchainTokenService — **no custom bridge**.
- **Allbridge Core** for native USDC (liquidity pools, no wrapping).
- **Single-asset deposit via Soroswap aggregator** (deposit USDC → contract buys basket,
  `out_min` on every leg).
- Cross-chain Folios are a **separate, labeled** product surface (bridge risk stacks on
  contract risk); native-only Folios stay the default.
- New contract-side surface: an inbound hook the ITS TokenManager calls when wrapped tokens
  land at the Folio, which then updates the basket and mints shares to the user.

### Phase 3 — Regulated-asset baskets (2027)

- **ReservePool** holding allowlisted BENJI; yield accrues to Folio NAV via daily dividend airdrops.
- Per-asset **transfer eligibility** enforced with the OZ AllowList extension (designed for from ADR-002 onward).
- Gated on: FT/MoonPay institutional KYC, securities-law structuring (fund-of-funds), and
  DTCC asset availability. Legal-and-partnership track, kept out of the critical code path.

---

## 4. How we work (process, so the system stays in check)

1. **One stage at a time**, in the order above. A stage isn't "done" until its checklist
   items in [`CHECKLIST.md`](./CHECKLIST.md) are ticked *and* its tests pass.
2. **After every stage**, append an entry to [`DECISION_LOG.md`](./DECISION_LOG.md):
   what we built, key decisions and *why*, anything deferred, and any interface that turned
   out different from this plan. This is the "keep the system in check" record you asked for.
3. **External dependencies** are tracked in [`EXTERNAL_DEPENDENCIES.md`](./EXTERNAL_DEPENDENCIES.md).
   Anything marked 🚧 must be resolved (or explicitly waived by you) **before** the stage that needs it.
4. **Security is not simplified away**: checks-effects-interactions on every fund movement,
   oracle staleness + divergence guards, multisig admin, minimal custom code over audited
   OZ components. Post-hackathon: SCF → SDF-sponsored audit (Audit Bank).
5. **Every non-trivial contract fn ships a test** (Soroban test env + the SEP-40 mock feed).
   Money paths get failure-case tests, not just happy-path.

---

## 5. Open questions for you (need answers before/early in Phase 1)

1. **Team size** — solo, or 2–4 builders? Determines whether frontend (Stage 1.5) runs in
   parallel with contracts or after.
2. **Testnet assets** — confirm we deploy mock SAC tokens for any of {XLM, USDC, EURC, AQUA,
   VELO} that lack a usable testnet issuer (default plan: yes, mock what's missing).
3. **Basket final composition** — PRD proposes XLM 40 / AQUA 20 / VELO 15 / USDC 15 / EURC 10.
   Confirm, or adjust to whatever Reflector actually prices (see dependency 🚧-1).
4. **Working name** — keep "Nebula DTF" or rename before mainnet deploy (token symbol is baked in).
```
