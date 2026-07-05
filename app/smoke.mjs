// Node smoke test: dynamic client against the live testnet folio.
// Run: node smoke.mjs
import { contract } from "@stellar/stellar-sdk";

const c = await contract.Client.from({
  contractId: "CAG2JRYQ4HROM5NX2PFWUPY5T2EEJPPQNWKSLHTNCFDHN7KWIFV7VR4Y",
  networkPassphrase: "Test SDF Network ; September 2015",
  rpcUrl: "https://soroban-testnet.stellar.org",
});

const nav = (await c.nav()).result;
const assets = (await c.get_assets()).result;
const supply = (await c.total_supply()).result;
console.log("nav:", nav);
console.log("assets:", assets.length, assets.map((a) => a.token.slice(0, 6)).join(","));
console.log("supply:", supply);
if (typeof nav.per_share !== "bigint" || nav.per_share <= 0n) throw new Error("bad NAV");
if (assets.length !== 5) throw new Error("bad assets");
console.log("SMOKE OK");
