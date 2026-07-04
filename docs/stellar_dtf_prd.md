# PRD / SRS — Nebula DTF: Decentralized Token Folios on Stellar

**Version:** 1.0
**Date:** 4 July 2026
**Context:** Stellar Garage Delhi (Build Station, 21-day residency), 4–25 July 2026, Innov8 CP Delhi. Organized by Stellar + Rise In. Mainnet deployment required before Demo Day (25 July 2026).
**Working name:** "Nebula DTF" (placeholder — rename freely)

---

## 1. Executive Summary

Nebula DTF is the first Decentralized Token Folio (on-chain index/basket fund) protocol on the Stellar blockchain. A DTF lets a user hold one token that represents proportional ownership of a basket of underlying assets — the on-chain equivalent of an ETF, mintable and redeemable 24/7 with no intermediary.

The product ships in three phases:

1. **Phase 1 (21-day hackathon):** Stellar-native DTF — a Soroban contract holding SAC-wrapped native assets (XLM, USDC, EURC, AQUA, VELO), with live NAV from Reflector/DIA oracles, proportional mint/redeem, deployed to mainnet.
2. **Phase 2 (months 1–6):** Cross-chain baskets — wETH/wBTC/wSOL via Axelar ITS, native USDC via Allbridge Core; yield baskets; Soroswap-powered single-asset deposit (deposit USDC, contract buys the basket).
3. **Phase 3 (2027):** Regulated-asset baskets — DTCC tokenized Russell 1000 stocks, ETFs, and US Treasuries arriving natively on Stellar in H1 2027, plus BENJI (Franklin Templeton money market fund) via an institutional reserve-pool integration.

**Why now:** DTCC — the post-trade backbone of Wall Street, custodian of $114T in assets — selected Stellar as its first public blockchain for tokenized securities (announced 27 May 2026; limited production trades begin July 2026; full asset availability H1 2027). No DTF/basket product exists on Stellar today. Whoever builds the audited basket primitive now becomes the default portfolio layer for the assets arriving in 2027.

---

## 2. Problem Statement

1. **On Stellar today, there is no way to hold diversified exposure in one token.** A user wanting exposure to the Stellar ecosystem must manage 5+ trustlines, 5 wallets/balances, and 5 price charts (XLM, USDC, EURC, AQUA, VELO, …).
2. **Stellar's asset base is institutionalizing faster than its consumer product layer.** BENJI ($1.98B AUM suite-wide), Circle USDC/EURC, MGUSD (MoneyGram), Spiko/Ondo treasuries, and soon DTCC tokenized securities all live on Stellar — but there is no retail-friendly wrapper to hold combinations of them.
3. **Existing DTF protocols (Reserve, Index Coop, Jupiter DTF) do not serve Stellar** and cannot easily: Reserve is on Ethereum/Base (Solana "soon"), and each Reserve DTF is 100% backed by assets *on the same chain* — none of them can hold Stellar-native assets like BENJI-on-Stellar or DTCC-issued securities.

---

## 3. Why Now — The Timing Case (with data)

| Signal | Data | Source |
|---|---|---|
| DTCC picked Stellar as first public chain for tokenized securities | Russell 1000 stocks, ETFs, US Treasuries; limited production trades July 2026; full rollout H1 2027 | [DTCC announcement](https://www.dtcc.com/news/2026/may/27/tokenization-service-to-connect-with-stellar-public-blockchain-as-dtc-advances-multi-chain-strategy), [CoinDesk](https://www.coindesk.com/business/2026/05/31/how-stellar-became-part-of-dtcc-s-tokenization-push-for-wall-street-securities-onchain) |
| SEC no-action letter enabling DTCC tokenization | Granted December 2025 for Russell 1000, ETFs, Treasuries | [Genfinity](https://genfinity.io/2026/05/27/dtcc-stellar-tokenization-dtc-custodied-assets-2027/) |
| Stellar chain TVL growth | Crossed $200M April 2026 (~$197.4M peak, $161M May); 284% YoY growth through 2025 | [DefiLlama](https://defillama.com/chain/stellar), [CryptoNews](https://cryptonews.net/news/altcoins/32925950/) |
| Broader tokenized asset footprint on Stellar | ~$2.4B across 65 issuances | [Stellar DeFi blog](https://stellar.org/blog/ecosystem/what-the-defi-is-happening-on-stellar) |
| BENJI growth | ~$650M → $1.98B AUM (suite) in first 4 months of 2026; +140% investor growth Apr 2024→Mar 2026; 3.56% 7-day yield | [Stellar/FT press](https://stellar.org/press/franklin-templeton-stellar-development-foundation-mark-five-years-of-benji-the-first-u-s-registered-tokenized-money-market-fund), [FT fund page](https://www.franklintempleton.com/investments/options/money-market-funds/products/29386/SINGLCLASS/franklin-on-chain-u-s-government-money-fund/FOBXX) |
| Proven DTF demand (category) | Reserve Protocol: ~$204M TVL; Yield DTFs ~$200M+ (fast PMF), Index DTFs $1.7M (slow) | [DefiLlama Reserve](https://defillama.com/protocol/reserve-protocol), [Messari](https://messari.io/report/reserve-protocol-the-rise-of-onchain-market-benchmarks) |
| No competitor on Stellar | Closest: Comet (Balancer-style weighted AMM, infrastructure not product) | [SCF recap](https://stellar.org/blog/ecosystem/stellar-community-fund-recap-financial-innovation-powered-soroban) |

**Category lesson (critical):** Reserve's Yield DTFs (yield-bearing baskets) found fast PMF ($200M+); their pure Index DTFs did not ($1.7M since Feb 2025). Index Coop peaked at $500M TVL in 2021 and declined to ~$52M. **Conclusion: build yield-bearing baskets, not passive indexes.** Stellar is uniquely positioned for this because BENJI (regulated, ~3.5% yield, daily on-chain dividends) exists natively — Ethereum index products have no equivalent regulated yield component.

---

## 4. Product Definition

### 4.1 Core Object: The Folio

A **Folio** is a Soroban smart contract that:
- Holds N underlying Stellar assets (via SAC — Stellar Asset Contract interface, SEP-41)
- Defines target weights (e.g., 40% XLM / 25% USDC / 15% EURC / 10% AQUA / 10% VELO)
- Mints **Folio shares** (SEP-41 fungible token, built on OpenZeppelin Stellar Contracts library) against deposits
- Redeems shares pro-rata for the underlying at any time
- Computes live NAV via oracle price feeds

### 4.2 Launch Folios (Phase 1)

| Folio | Composition | Thesis |
|---|---|---|
| **Stellar Ecosystem Folio** | XLM 40% / AQUA 20% / VELO 15% / USDC 15% / EURC 10% | "Own the Stellar ecosystem in one token" — narrative product |
| **Stable Yield Folio** (Phase 1.5) | USDC 50% / EURC 30% / yield-bearing asset 20% | Conservative; the Yield-DTF shape that actually has PMF |

### 4.3 Mint / Redeem Mechanics

**Phase 1 — Proportional deposit (no swaps, no slippage):**
User deposits assets in exact basket ratios → contract mints shares at NAV. Redeems burn shares and return the underlying pro-rata. This sidesteps Stellar's thin DEX liquidity (~$23.4M SDEX TVL, ~$37.3M Aquarius) entirely at mint/redeem.

**Phase 2 — Single-asset deposit via Soroswap:**
User deposits only USDC → contract routes swaps through [Soroswap aggregator](https://soroswap.finance/) (queries Aquarius + Phoenix + Soroswap AMM + native SDEX order book; REST API at api.soroswap.finance + TypeScript SDK) → acquires the basket → mints shares. Slippage-bounded (`out_min` on every leg).

### 4.4 NAV & Oracles

- **Reflector** (live on mainnet, SCF-backed, purpose-built for Stellar): crypto prices, FX rates, CEX/DEX rates, TWAP helpers. [reflector.network/docs](https://reflector.network/docs)
- **DIA** (live on Soroban testnet; 20,000+ assets; also xRandom randomness): [DIA on Soroban](https://www.diadata.org/blog/post/dia-deploys-oracle-on-stellar-soroban/)
- **Note: Pyth does NOT support Stellar/Soroban.** Do not design against it.
- NAV = Σ(asset_balance × oracle_price) / total_share_supply, recomputed on-chain at every mint/redeem; UI polls for display (~5s cadence, matching Stellar finality).
- Resilience: median of Reflector + DIA where both available; staleness checks; circuit-breaker pausing mint/redeem if feeds diverge > threshold.

### 4.5 Rebalancing (deliberately deferred)

- Phase 1: **static weights** — basket drifts with price; no rebalancing. Honest and safe at low TVL.
- Phase 2: quarterly governance-approved rebalancing executed via Soroswap with strict slippage bounds. Feasible under ~$500K TVL given current DEX depth; revisit as Stellar liquidity deepens post-DTCC.

### 4.6 Fees (business model)

- Mint fee: 0 (growth phase)
- Management fee: 0.3–0.5% annualized, accrued in shares (Reserve enforces a 15bps minimum on its platform — market reference)
- At current Stellar TVL this is not a revenue business; the moat is being the **standard basket primitive** on Stellar before the DTCC wave. Funding path: SCF Build Award (up to $150K in XLM) + sponsored audit via [Stellar Audit Bank](https://stellar.org/audit-bank/projects) (54 audited projects as of Feb 2026).

---

## 5. Cross-Chain Pipeline (Phase 2)

### 5.1 Bridge selection

| Bridge | Use for | Model | Notes |
|---|---|---|---|
| **Axelar ITS** (Stellar ITS live, "Hub mode") | ETH, wBTC, SOL, arbitrary tokens | Lock-and-mint → wrapped axlETH/axlBTC/axlSOL on Stellar | [Stellar ITS docs](https://docs.axelar.dev/dev/send-tokens/stellar/intro/); components: Gateway, TokenManager, GasService, InterchainTokenService; ~75-validator network; 70+ chains via GMP |
| **Allbridge Core** | USDC/USDT only | Native liquidity pools — **no wrapping**; real Circle USDC arrives on Stellar; relayer auto-creates trustlines | [Allbridge Core](https://docs-core.allbridge.io/) |

**Do not build a custom bridge.** The April 2026 Secret Network incident ($4.67M drained) came from a team *adapting* Axelar integration code and removing source-validation checks — the lesson is to use audited bridge infrastructure exactly as shipped. ([The Block](https://www.theblock.co/post/405459/secret-networks-axelar-bridge-drained-for-4-67-million-in-infinite-mint-exploit-that-went-unnoticed-for-seven-days))

### 5.2 Inbound flow (Ethereum → Stellar DTF)

```
User approves Axelar Gateway (Ethereum) → calls interchain_transfer(
    token=ETH, amount, destination_chain="stellar",
    destination_address=<DTF contract>, gas in ETH)
→ Ethereum Gateway locks ETH in escrow
→ Axelar validators attest; ITS Hub routes message
→ Stellar TokenManager mints axlETH to the DTF contract
→ DTF updates basket, recalculates NAV, mints Folio shares to user
```
Redemption reverses it: burn shares → receive axlETH → `interchain_transfer` back → Axelar burns axlETH → unlocks native ETH on Ethereum.

### 5.3 Multi-chain baskets — answered

Yes: one Folio can hold assets originating on many chains, because everything arrives as a Stellar token (native, Circle-native via Allbridge, or Axelar-wrapped). The Folio share token itself always lives on Stellar. Uniswap **LP positions** (v3 NFTs) are out of scope — bridge the underlying tokens, not positions.

### 5.4 Risk disclosure requirement

Wrapped assets stack bridge risk on top of contract risk: if Axelar's Ethereum escrow were exploited, axlETH inside the Folio becomes unbacked even though ETH itself is fine. Cross-chain Folios must be visually and contractually separated from native-only Folios in the UI, with explicit risk labeling.

---

## 6. BENJI & DTCC Strategy (Phase 3)

### 6.1 BENJI facts (July 2026)

- On-chain share token of Franklin OnChain U.S. Government Money Fund (FOBXX); blockchain is the *official system of record*; launched on Stellar 2021 — first US-registered mutual fund on a public chain.
- $1.98B AUM across the BENJI suite (Apr 29, 2026); ~$650M+ on Stellar (2nd-largest RWA on the chain); 8 chains total.
- 7-day effective yield 3.56% (June 29, 2026); intraday yield accrual by the second (patent-pending, June 2025); daily on-chain dividends 365 days/year, airdropped as new BENJI tokens.
- **Hard constraint discovered in research: BENJI is allowlist-gated.** Only Franklin Templeton KYC'd, allowlisted addresses on allowlisted chains can hold it. Transfers reconcile through FT's transfer agent. There is **no permissionless path** to put BENJI in a public contract. ([Eco deep dive](https://eco.com/support/en/articles/15254016-benji-deep-dive-2026-franklin-templeton-s-tokenized-money-market))

### 6.2 The reserve-pool model (user's proposal, validated with caveats)

Proposal: the protocol entity pre-buys and holds BENJI in a **reserve contract**; when a user mints a yield Folio, the main contract allocates BENJI from the reserve — the user never needs their own BENJI or FT onboarding.

**Assessment — workable, but it is an institutional partnership, not a hack:**
1. The reserve contract address (or a custodial wallet feeding it) must itself be **KYC'd and allowlisted by Franklin Templeton** — via the Benji institutional channel or [MoonPay Trade](https://thedefiant.io/news/tradfi-and-fintech/franklin-templeton-benji-moonpay-trade-onchain-stablecoin-swaps) (single-API institutional platform supporting BENJI↔stablecoin swaps; institutional-KYC gated).
2. Users holding Folio shares backed partly by BENJI = **a fund holding a mutual fund** — a fund-of-funds structure. The Folio share itself would very likely be a security in the US and require legal structuring (or geofencing) before launch. This is a lawyer conversation, not a code problem.
3. Daily BENJI dividend airdrops arrive to the reserve → accrue to Folio NAV automatically — this is the killer feature (a basket with a regulated ~3.5% yield floor) and why the structuring effort is worth it.
4. **Interim substitutes** while BENJI partnership is pursued: yXLM, or other yield-bearing Stellar RWAs with less restrictive transfer models (evaluate Spiko / Ondo issuances on Stellar case-by-case).

### 6.3 DTCC context (why Phase 3 is credible)

- DTCC = post-trade infrastructure for effectively all US securities; >$114T custodied/cleared. Acquired **Securrency** (2023) → now DTCC Digital Assets, led by Nadine Chakar; Securrency's CTO Dan D'Onofrio co-authored **CAP-0035**, the Stellar protocol amendment adding native asset clawback — Stellar's compliance layer was partly built by the people now running DTCC's digital asset strategy. ([CoinDesk](https://www.coindesk.com/business/2026/05/31/how-stellar-became-part-of-dtcc-s-tokenization-push-for-wall-street-securities-onchain))
- Why Stellar won: protocol-native compliance (clawback, transfer restrictions, authorization flags), post-trade-grade throughput/fees, and an institutional track record (MoneyGram, Circle, Franklin Templeton).
- Timeline: SEC no-action letter Dec 2025 → announcement May 27, 2026 → limited production trades July 2026 → broader service Oct 2026 → tokenized Russell 1000 / ETFs / Treasuries on Stellar H1 2027.
- **Expectation setting:** DTCC-tokenized securities will almost certainly carry their own allowlist/eligibility regime like BENJI. Phase 3 Folios containing them will be permissioned products for eligible users — plan the architecture so a Folio can enforce per-asset transfer eligibility (OpenZeppelin Stellar AllowList extension exists for exactly this).

---

## 7. Technical Architecture

### 7.1 Stack

| Layer | Choice | Why |
|---|---|---|
| Contracts | Rust / Soroban | 3–5s finality, sub-cent fees |
| Token standard | SEP-41 via [OpenZeppelin Stellar Contracts](https://docs.openzeppelin.com/stellar-contracts) (audited; Certora formal verification; SDF partnership through Dec 2026) | Don't hand-roll the share token; AllowList/BlockList extensions available for Phase 3 |
| Underlying asset access | SAC (Stellar Asset Contract) | Exposes any classic Stellar asset to Soroban; ~97% less CPU, ~47% lower fees than pure Soroban tokens |
| Oracles | Reflector (primary) + DIA (secondary/median) | Only oracles actually on Stellar |
| Swap routing (Phase 2) | Soroswap aggregator API/SDK | Routes across Aquarius + Phoenix + Soroswap AMM + SDEX |
| Wallets/UX | PasskeyKit + Launchtube | Face-ID wallet creation, sponsored fees — no seed phrase, no gas UX |
| Data/API | Horizon (horizon.stellar.org) + Soroban RPC | Balances, tx submission, event streaming |
| Bridges (Phase 2) | Axelar ITS (tokens) + Allbridge Core (stablecoins) | Audited, live on Stellar |

### 7.2 Contract map

```
FolioFactory ── creates ──> Folio (per basket)
                              ├── holds SAC balances (XLM, USDC, EURC, AQUA, VELO…)
                              ├── mint(deposit[]) / redeem(shares)
                              ├── nav() ← OracleRouter (Reflector + DIA, median + staleness guard)
                              ├── pause() circuit breaker (oracle divergence / admin)
                              └── FolioShare (SEP-41, OpenZeppelin fungible)
ReservePool (Phase 3) ── allowlisted BENJI custody ──> allocates to Folios
```

### 7.3 Security requirements

- Reentrancy-safe mint/redeem ordering (checks-effects-interactions); Soroban's model helps but don't rely on it blindly.
- Oracle: staleness bound (reject prices older than X ledgers), two-source median, divergence circuit breaker.
- Admin keys behind multisig; upgradeability decision documented (prefer immutable Folio + factory-versioning over upgradeable proxies).
- Post-hackathon: apply to SCF → qualify for SDF-sponsored audit via Audit Bank.

---

## 8. 21-Day Implementation Plan (4–25 July 2026)

**Team assumption:** 2–4 builders. Scope is Phase 1 only. Build Station days: Jul 4 (kickoff), Jul 11 (review), Jul 18 (pre-demo), Jul 25 (Demo Day, mainnet required).

### Week 1 — Contracts core (Jul 4–10)
- D1: Repo, Soroban toolchain, testnet accounts; import OpenZeppelin Stellar library; define Folio interfaces.
- D2–3: Folio contract — multi-asset custody via SAC clients; proportional `mint`/`redeem`; FolioShare (SEP-41).
- D4–5: OracleRouter — Reflector integration on testnet, NAV function, staleness guard; unit tests.
- D6–7: FolioFactory; deploy Stellar Ecosystem Folio to **testnet**; end-to-end mint→NAV→redeem test. *Checkpoint for Jul 11 review: working testnet demo.*

### Week 2 — Product & UX (Jul 11–17)
- D8–9: Web app (mobile-first): PasskeyKit onboarding (Face ID wallet), Launchtube fee sponsorship.
- D10–11: Folio page — composition donut, live NAV (5s poll via Horizon/RPC), user's shares & P&L; mint/redeem flows with clear asset-ratio helper.
- D12: DIA testnet feed as second source, median logic, circuit breaker.
- D13–14: Testnet beta with cohort members (real users, screenshots for progress updates — Rise In expectation). Collect friction notes.

### Week 3 — Mainnet & Demo (Jul 18–25)
- D15 (Jul 18, Build Station): pre-demo review; lock scope; fix beta findings.
- D16–17: **Mainnet deployment** (Rise In sponsors mainnet): deploy Factory + Ecosystem Folio; seed with small real balances; verify oracle feeds on mainnet.
- D18–19: Hardening — failure paths, pause drill, slippage-free redeem verification; simple landing page + docs.
- D20: Dry run; pitch deck: gap → DTCC timing → live mainnet demo → Phase 2/3 roadmap; record backup demo video.
- D21 (Jul 25): **Demo Day** — live mint on mainnet from a judge's phone via passkey wallet (no seed phrase, no gas), show NAV moving, redeem live.

**Deliberately cut from 21 days:** swaps/single-asset deposit, rebalancing, cross-chain, BENJI, fees, governance. They are roadmap slides, not code.

---

## 9. PMF Analysis

### Scorecard

| Dimension | Score | Basis |
|---|---|---|
| Proven category demand (yield baskets) | 8/10 | Reserve Yield DTFs $200M+ TVL |
| Novelty on Stellar | 9/10 | No competitor; Comet is infra, not product |
| Market timing (DTCC narrative) | 9/10 | First-mover before H1 2027 asset wave |
| Native asset breadth today | 4/10 | Thin; improves materially with BENJI + DTCC |
| DEX liquidity for rebalancing | 3/10 | $23.4M SDEX / $37.3M Aquarius — designed around via proportional deposits |
| Regulatory (crypto-only Folio) | 7/10 | Clean until regulated assets enter |
| Regulatory (BENJI/DTCC Folios) | 3/10 | Fund-of-fund structuring + allowlists required |
| Revenue at current TVL | 3/10 | Infra bet, not fee business yet |
| 21-day scope realism (Phase 1) | 8/10 | Static basket + proportional mint is tight but honest |
| **Overall** | **6.5/10** | Strong infrastructure bet; weak near-term fee business; exceptional timing |

### The debate, condensed

- **"DTFs failed everywhere — Index Coop fell $500M→$52M."** → Passive *index* DTFs failed; *yield* DTFs found PMF fast. Stellar uniquely has a regulated on-chain yield asset (BENJI) to anchor yield baskets.
- **"Stellar DEX liquidity can't support rebalancing."** → True; so Phase 1 uses proportional deposits (no swaps) and static weights; rebalancing waits for post-DTCC liquidity.
- **"Bridge risk kills cross-chain baskets."** → Contained: native-only Folios are the default; cross-chain Folios are opt-in, labeled, and use audited Axelar/Allbridge only.
- **"A stablecoin-heavy basket is boring."** → It's sold as the Stellar-ecosystem narrative token today and becomes genuinely diversified when DTCC equities land — the boring version is the wedge, not the destination.
- **"Why not just hold XLM?"** → One asset vs. basket + euro exposure + DeFi tokens + (later) 3.5% regulated yield floor + one-token UX for passkey users who will never manage five trustlines.

---

## 10. Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Oracle failure / stale prices | High | Two-source median, staleness bounds, pause breaker |
| Thin DEX liquidity | High | Proportional deposit model; no swap dependency in Phase 1 |
| Bridge exploit (Phase 2) | High | Audited bridges only; segregated cross-chain Folios; explicit disclosure |
| BENJI allowlist blocks integration | Medium | Institutional channel/MoonPay Trade partnership; interim yield substitutes |
| Securities-law exposure (Phase 3) | High | Legal structuring before any regulated-asset Folio; geofencing if needed |
| Smart contract bug | High | OpenZeppelin audited components; SCF → sponsored audit; minimal custom code |
| Reserve Protocol enters Stellar | Medium | Their DTFs are same-chain-backed EVM products; first-mover + Stellar-native depth is the moat |
| Cold-start TVL | Medium | Cohort + Stellar community as seed users; SCF funding; narrative marketing around DTCC |

---

## 11. Success Metrics

- **Demo Day (Jul 25):** live mainnet Folio; ≥15 real users minted (cohort); judge mints live via passkey in <60s.
- **Month 3:** SCF Build Award submitted; audit slot; $50K+ TVL; single-asset deposit shipped.
- **Month 6:** cross-chain Folio live; FT/MoonPay institutional conversation started.
- **2027:** first DTCC-asset Folio design (permissioned) ready when assets go live.

---

## 12. Source Index

**Stellar / ecosystem:** [Soroban](https://stellar.org/soroban) · [Horizon API](https://developers.stellar.org/docs/data/apis/horizon) · [SAC docs](https://developers.stellar.org/docs/tokens/stellar-asset-contract) · [OpenZeppelin Stellar Contracts](https://docs.openzeppelin.com/stellar-contracts) · [Audit Bank](https://stellar.org/audit-bank/projects) · [SCF Awards ($150K)](https://communityfund.stellar.org/awards) · [Stellar TVL — DefiLlama](https://defillama.com/chain/stellar) · [Stellar DeFi overview](https://stellar.org/blog/ecosystem/what-the-defi-is-happening-on-stellar)

**DEX/liquidity:** [Soroswap](https://soroswap.finance/) · [Soroswap API](https://docs.soroswap.finance/soroswap-api) · [Aquarius](https://aqua.network/) · [Aquarius Soroban functions](https://docs.aqua.network/developers/aquarius-soroban-functions) · [SDEX TVL](https://defillama.com/protocol/stellar-dex) · [Path payments](https://developers.stellar.org/docs/build/guides/transactions/path-payments)

**Oracles:** [Reflector](https://reflector.network/docs) · [DIA on Soroban](https://www.diadata.org/blog/post/dia-deploys-oracle-on-stellar-soroban/) · [Stellar oracle providers](https://developers.stellar.org/docs/data/oracles/oracle-providers)

**Bridges:** [Axelar Stellar ITS](https://docs.axelar.dev/dev/send-tokens/stellar/intro/) · [Axelar ITS](https://www.axelar.network/its) · [Allbridge Core](https://docs-core.allbridge.io/) · [Secret/Axelar exploit — The Block](https://www.theblock.co/post/405459/secret-networks-axelar-bridge-drained-for-4-67-million-in-infinite-mint-exploit-that-went-unnoticed-for-seven-days)

**BENJI / DTCC:** [BENJI 5-year press release](https://stellar.org/press/franklin-templeton-stellar-development-foundation-mark-five-years-of-benji-the-first-u-s-registered-tokenized-money-market-fund) · [FOBXX fund page](https://www.franklintempleton.com/investments/options/money-market-funds/products/29386/SINGLCLASS/franklin-on-chain-u-s-government-money-fund/FOBXX) · [BENJI deep dive (allowlist)](https://eco.com/support/en/articles/15254016-benji-deep-dive-2026-franklin-templeton-s-tokenized-money-market) · [Benji DevHub](https://digitalassets.franklintempleton.com/benji/benji-contracts/) · [MoonPay Trade + BENJI](https://thedefiant.io/news/tradfi-and-fintech/franklin-templeton-benji-moonpay-trade-onchain-stablecoin-swaps) · [DTCC announcement](https://www.dtcc.com/news/2026/may/27/tokenization-service-to-connect-with-stellar-public-blockchain-as-dtc-advances-multi-chain-strategy) · [DTCC × Stellar history — CoinDesk](https://www.coindesk.com/business/2026/05/31/how-stellar-became-part-of-dtcc-s-tokenization-push-for-wall-street-securities-onchain) · [DTCC case study — Stellar](https://stellar.org/case-studies/dtcc)

**DTF category:** [Reserve Protocol](https://reserve.org/) · [Reserve TVL](https://defillama.com/protocol/reserve-protocol) · [Reserve Index DTF docs](https://reserve-1.gitbook.io/docs/core-components/index-dtfs/overview) · [Messari on Reserve](https://messari.io/report/reserve-protocol-the-rise-of-onchain-market-benchmarks) · [Jupiter DTF](https://dtf.jup.ag/) · [Index Coop TVL](https://defillama.com/protocol/index-coop)

**UX:** [PasskeyKit](https://github.com/kalepail/passkey-kit) · [Smart wallets docs](https://developers.stellar.org/docs/build/apps/smart-wallets)
