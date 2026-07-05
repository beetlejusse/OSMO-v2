# Nebula DTF — Decision & Build Log

The running record that keeps the system in check. Two parts:
1. **ADRs** — architectural decisions (with rationale) made up front.
2. **Build log** — one entry appended **after every completed stage**: what was built,
   what changed vs the plan, what was deferred, and why.

Keep entries short and honest. When reality differs from
[`IMPLEMENTATION_PLAN.md`](./IMPLEMENTATION_PLAN.md), record it here — this doc wins.

---

## Part 1 — Architecture Decision Records

### ADR-001 — One Folio contract embeds its own share token
**Decision:** The Folio contract inlines OpenZeppelin's `fungible` base module and *is* its
own SEP-41 share token; no separate token contract.
**Why:** Mint is atomic (no cross-contract call to a token contract mid-mint), fewer
deployables, smaller audit surface.
**Trade-off:** The share token can't be reused independently of its Folio — fine, it never should be.

### ADR-002 — Do not use the OZ Vault (ERC-4626); custom multi-asset accounting
**Decision:** Build proportional mint/redeem on top of the OZ fungible *base*, not the Vault.
**Why:** Verified 2026-07-05 — the OZ Stellar Vault is **single-asset** (one underlying,
immutable after init). A Folio holds N assets. Using the Vault would fight the primitive.
**Consequence:** We own the shares↔basket math. Also keeps the door open for the AllowList
extension (Phase 3) which composes with the fungible base.

### ADR-003 — Proportional deposit/redeem, no swaps (Phase 1)
**Decision:** Users deposit all basket assets in ratio; redeem returns underlying pro-rata.
**Why:** Stellar DEX liquidity is thin (~$23M SDEX). Proportional = zero slippage, no swap
dependency, honest at low TVL. Single-asset deposit (Soroswap) is Phase 2.

### ADR-004 — Static weights (Phase 1)
**Decision:** No rebalancing; basket drifts with price.
**Why:** Safe and truthful at low TVL; rebalancing needs post-DTCC liquidity depth.

### ADR-005 — OracleRouter is one standalone contract, shared by all Folios
**Decision:** Deploy price logic (staleness, median, divergence) once; Folios reference it.
**Why:** One place to configure and audit oracle policy; deploy once, not per-Folio. The
Folio (which holds funds) owns the pause decision; the router only returns a validated price or errors.

### ADR-006 — Immutable Folios + factory versioning; no proxies
**Decision:** Folios are not upgradeable. New logic = new wasm version deployed by the factory; users opt in.
**Why:** Upgradeable proxies are a top exploit/audit surface. Immutability is the safer default at this scale.

### ADR-007 — Multisig admin; mint/redeem pausable
**Decision:** Admin keys behind multisig; mint/redeem can be paused by admin or by oracle divergence.
**Why:** Contain oracle failure and operator error without ever custodying user funds beyond the contract.

### ADR-008 — Use audited bridges exactly as shipped (Phase 2); never a custom bridge
**Decision:** Axelar ITS + Allbridge Core, unmodified integration code.
**Why:** The Apr 2026 Secret Network $4.67M drain came from a team *adapting* Axelar code and
removing source-validation. Cross-chain Folios stay segregated and risk-labeled.

### ADR-009 — Hand-rolled SEP-40 interface instead of the `sep-40-oracle` crate
**Decision:** Define `OracleAsset`/`PriceData`/`Sep40Client` ourselves in `crates/nebula-interfaces` (~40 lines).
**Why:** Discovered at pin time (2026-07-05): `sep-40-oracle` 1.4.0 requires soroban-sdk ^25 while
OpenZeppelin `stellar-tokens` 0.7.2 (the audited share-token base — the dependency actually worth
keeping) requires ^26.1. Two SDK majors cannot coexist in one contract. The SEP-40 client surface
is trivial; the OZ token internals are not.

### ADR-010 — Single-feed router in Phase 1; median lands in Stage 1.5 via router swap
**Decision:** OracleRouter ships with one feed per token (staleness + normalization + positivity).
The Reflector+DIA median and divergence breaker arrive as a new router deployment; Folios repoint
with admin-gated `set_router`.
**Why:** DIA integration is scheduled for Stage 1.5 anyway; the router holds no funds, so swapping
it is cheap — no reason to carry dead median code through the Week-1 audit surface.

### ADR-011 — Oracle-free money path after bootstrap
**Decision:** After the first mint, `mint`/`redeem` are purely proportional to current balances:
`deposit_i = ceil(bal_i × shares / supply)`, `out_i = floor(bal_i × shares / supply)`. The oracle
prices only (a) the bootstrap ratio check and (b) the `nav()` view. Rounding always favors the
folio. Pause blocks minting only — redemption is never pausable and works with a dead oracle
(proven by test `redeem_works_while_paused_and_with_dead_oracle`).
**Why:** This shrinks the attack surface dramatically: a compromised or stale oracle cannot
mis-price a recurring mint or block an exit. It also means mint needs per-leg `max_deposits`
bounds (balances can shift between simulation and submission) instead of ratio validation.

### ADR-012 — Test tokens are self-issued classic assets, `T`-prefixed
**Decision:** On testnet we issue classic assets `TAQUA`, `TVELO`, `TUSDC`, `TEURC` from a
dedicated `nebula-test-issuer` account and deploy their SACs; XLM uses the real native asset.
Prices come from `MockPriceFeed` (never deployed to mainnet). The router's per-token
`FeedSpec.asset` mapping means mainnet simply repoints each real token to Reflector.
**Why:** AQUA/VELO have no official testnet issuances (confirmed with user 2026-07-05); the
`T` prefix makes the mimicked asset obvious at a glance.

### ADR-013 — Frontend: dynamic contract client + Freighter interim wallet
**Decision:** The web app uses `contract.Client.from` (fetches the contract spec from the
chain at runtime) instead of generated TypeScript bindings, and ships with **Freighter** as
the interim wallet so the testnet beta can start. PasskeyKit + Launchtube slot in behind the
same `connectWallet()` seam once the Launchtube token arrives.
**Why:** No bindings package to regenerate on every contract change; Freighter needs zero
external approvals. The mint "asset-ratio helper" is free with this design: simulating
`mint` returns the exact required deposits, which the UI shows before the user signs
(then sends with a 0.5% `max_deposits` buffer).

---

## Part 2 — Build Log

> Template — copy for each completed stage:

### [YYYY-MM-DD] Stage X.Y — <name>
- **Built:** <what shipped>
- **Decisions this stage:** <key choices + why>
- **Changed vs plan:** <interfaces/approach that differed, or "none">
- **Deferred:** <what we consciously left out>
- **Tests:** <what's covered / notable failure cases>
- **External deps touched:** <accounts, tokens, APIs>

### [2026-07-05] Stages 1.0–1.3 — workspace, OracleRouter, Folio, Factory
- **Built:** Cargo workspace (`crates/nebula-interfaces` + 4 contracts); OracleRouter
  (feed map, staleness guard, ms-timestamp normalization, 14-dec price normalization);
  Folio (SAC custody, OZ fungible SEP-41 share token embedded, `init_mint` bootstrap with
  1% ratio tolerance, proportional `mint`/`redeem`, `nav()`, pause, admin `set_router`);
  FolioFactory (`deploy_v2` from stored wasm hash, registry, `set_wasm_hash` versioning);
  MockPriceFeed; testnet setup / price-refresh / test scripts. 27 tests green
  (8 router, 17 folio, 2 factory); all four wasm build clean (folio 22.8 KB).
- **Decisions this stage:** ADR-009 (drop `sep-40-oracle` crate — SDK 25 vs 26 conflict with OZ),
  ADR-010 (single-feed router now, median via router swap at Stage 1.5),
  ADR-011 (oracle-free proportional money path; mint bounded by `max_deposits`; redeem never pausable),
  ADR-012 (T-prefixed self-issued test tokens).
- **Changed vs plan:** OZ Vault confirmed unusable (single-asset) exactly as ADR-002 predicted;
  `sep-40-oracle` crate dropped (ADR-009); ratio validation on recurring mint replaced by
  balance-proportional math + slippage bounds (ADR-011) — strictly safer than the PRD sketch.
- **Deferred:** two-source median + divergence breaker (Stage 1.5); `#[contractevent]` migration
  (SDK 26 deprecates `events().publish` — warnings only, cosmetic); multisig admin setup
  (before mainnet, ADR-007).
- **Tests:** happy paths, wrong-ratio/dust/double-bootstrap rejects, slippage bound, paused
  semantics, stale-oracle behavior on both sides (blocks bootstrap; does NOT block mint/redeem),
  full-supply redeem, share transferability, constructor guards, factory salt reuse.
- **External deps touched:** Rust updated 1.84→1.96.1 (deps need edition2024); Stellar CLI 27.0.0
  via winget (`C:\Program Files (x86)\Stellar CLI`); `wasm32v1-none` target; testnet scripts
  written but **not yet run** — that's Stage 1.4.

### [2026-07-05] Stage 1.4 — testnet end-to-end (Jul 11 checkpoint met early)
- **Built/Deployed (testnet):** TAQUA/TVELO/TUSDC/TEURC SACs issued+minted; MockPriceFeed
  `CD7WLD…PQBE`; OracleRouter `CC45K7…UBKC`; Factory `CCM5OZ…OC7W`; **SEF Folio
  `CAG2JRYQ4HROM5NX2PFWUPY5T2EEJPPQNWKSLHTNCFDHN7KWIFV7VR4Y`** (XLM 40 / TAQUA 20 /
  TVELO 15 / TUSDC 15 / TEURC 10). All addresses in `.stellar/nebula-testnet.json`.
- **Verified live:** bootstrap $100 → 99.99972 shares at exactly $1.00 NAV; proportional
  mint of 10 shares pulled ceil-rounded pro-rata deposits; redeem of 10 returned
  floor-rounded amounts; NAV/share rose to 1.0000000025 after the cycle — rounding dust
  accrues to holders as designed (ADR-011).
- **Decisions this stage:** scripts hardened for PS 5.1 (ASCII-only, quoted `'--'`
  passthrough, literal `\"` JSON escaping, local ErrorActionPreference in the CLI wrapper,
  SAC-deploy fallback to `contract id asset` on re-run). Router max_age = 24h on testnet
  only (mock prices are static); mainnet uses a tight bound with live Reflector.
- **Deferred:** wiring XLM to the real Reflector testnet feed (`CAVLP5…D6HLP`) — mock keeps
  dev deterministic; swap when the median router lands (Stage 1.5).
- **External deps touched:** testnet identities funded via friendbot; ~15 testnet txs.

### [2026-07-05] Stage 1.5 (oracle half) — median router v2 live, folio repointed
- **Built:** OracleRouter v2 — per-token `Vec<FeedSpec>` (1–2 feeds), midpoint-of-2 median,
  `max_divergence_bps` circuit breaker (trips `Divergence`), `allow_single` fallback when one
  source is stale/dead, `try_lastprice` so a *broken* feed contract degrades to an error
  instead of trapping the transaction. Single-feed error semantics preserved from v1.
  30 tests green workspace-wide (router 11).
- **Deployed (testnet):** router v2 `CBOB27FS…DJWWM` (5% divergence, allow_single, 24h max_age),
  second MockPriceFeed as DIA stand-in `CBYG366L…FBLO`; all 5 tokens wired to both feeds;
  live SEF folio repointed with `set_router` — NAV unchanged through the swap, proving the
  ADR-010 router-upgrade path end-to-end.
- **Decisions this stage:** breaker design stays consistent with ADR-011 — divergence halts
  *pricing* (bootstrap, nav), never mint/redeem, so a tripped breaker cannot trap funds.
  Median of 2 = midpoint; timestamp = older of the two (conservative freshness).
- **Deferred:** real DIA testnet feed (need their verified contract address — the stand-in is
  interface-identical); `#[contractevent]` migration (cosmetic warnings).
- **Changed vs plan:** none — this closes the two Stage-1.1 items deferred by ADR-010.

### [2026-07-05] Stage 1.5 (app half) — folio web app built; review fix; initial commits
- **Built:** `app/` — Vite + React + TS single-page folio dashboard: NAV/total-value/supply
  cards on a 5s poll, SVG weights donut + holdings table, wallet connect (Freighter),
  simulate-first mint quote → confirm with 0.5% buffered `max_deposits`, redeem, position
  value, oracle-guard surfacing (a tripped breaker shows "NAV unavailable" instead of
  breaking the page). `npm run build` clean; `smoke.mjs` verifies the dynamic client against
  the live testnet folio (NAV/assets/supply reads).
- **Review pass:** full codebase read-through. One defect found+fixed: `redeem` with zero
  supply hit divide-by-zero (host trap) instead of a clean `NotBootstrapped` error —
  regression test added (31 tests total). Stale router-v1 test snapshots purged.
- **Commits:** repo history started — docs / contracts / scripts / snapshots-cleanup / app.
- **Decisions this stage:** ADR-013 (dynamic client + Freighter interim).
- **Deferred:** PasskeyKit + Launchtube (🚧 external token, the only open Phase-1 gate);
  browser-manual test of mint/redeem with a funded Freighter account (cohort beta,
  Stage 1.6); bundle code-splitting (stellar-sdk is 349KB gzipped — acceptable).
- **External deps touched:** npm registry (React 19, stellar-sdk 14, freighter-api 4,
  Vite 6); Node 22.13 local.
```
