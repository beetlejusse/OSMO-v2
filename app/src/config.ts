// Testnet deployment (see .stellar/nebula-testnet.json + docs/DECISION_LOG.md).
// Override via VITE_* env vars for other networks.

export const NETWORK_PASSPHRASE =
  import.meta.env.VITE_NETWORK_PASSPHRASE ?? "Test SDF Network ; September 2015";
export const RPC_URL =
  import.meta.env.VITE_RPC_URL ?? "https://soroban-testnet.stellar.org";
export const FOLIO_ID =
  import.meta.env.VITE_FOLIO_ID ??
  "CAG2JRYQ4HROM5NX2PFWUPY5T2EEJPPQNWKSLHTNCFDHN7KWIFV7VR4Y";

/** Display metadata per underlying token (SAC contract id -> info). */
export const TOKEN_INFO: Record<string, { symbol: string; color: string }> = {
  CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC: { symbol: "XLM", color: "#7b68ee" },
  CB3OYUNWSCZF7W3XR3QAAR6JCVSOFYG54CBY33MXO4SCUCBK4LU6CUQL: { symbol: "TAQUA", color: "#9f4ef5" },
  CBHOVSG2TI3KIKAO5IQP5A4DD3SI3UNFBSIIXF4HHYOW5ETNW4BHQXUB: { symbol: "TVELO", color: "#f5a623" },
  CC2K3NLXUWJ7OW2PKQXHYVAF67VLRK7EXO6FPI223ICIHZPOWBAPQVD5: { symbol: "TUSDC", color: "#2775ca" },
  CAJ4MSRBF4QXS6WOOE63FCMY6LPHLPZ356Y4TA2456FG77F4YJSEV5K2: { symbol: "TEURC", color: "#1a9c6b" },
};

export const SHARE_DECIMALS = 7;
export const PRICE_DECIMALS = 14;
