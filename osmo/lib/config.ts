// Public testnet deployment defaults. Env vars can override these after a
// redeploy, but local/Vercel env drift should not blank the frontend.
//
// Next.js inlines `process.env.NEXT_PUBLIC_*` at build time only when referenced
// as a full literal, so each var is spelled out here rather than looped over.

const CURRENT_TESTNET = {
  NETWORK_PASSPHRASE: "Test SDF Network ; September 2015",
  RPC_URL: "https://soroban-testnet.stellar.org",
  HORIZON_URL: "https://horizon-testnet.stellar.org",
  // Aquarius AMM router on Stellar *testnet* (NOT the mainnet router).
  // Docs: https://docs.aqua.network/developers/reference/addresses-and-networks
  AQUARIUS_ID: "CBCFTQSPDBAIZ6R6PJQKSQWKNKWH2QIV3I4J72SHWBIK3ADRRAM5A6GD",
  // Aquarius shared test-asset issuer (AQUA, USDC, USDT, BTC, …).
  AQUARIUS_TEST_ISSUER: "GAHPYWLK6YRN7CVYZOO4H3VDRZ7PVF5UJGLZCSPAEIKJE2XSWF5LAGER",
  // Folio still holds self-issued tst* stand-ins until a redeploy swaps the basket.
  TEST_ISSUER: "GDIYTKW2SS3OVYPHZJ2QOJSSKVPME5GQLRHDJNZ3OZRP6QJHAEFXTZT3",
  FOLIO_ID: "CCOMNDEZSPR7ZXCPCVOKCGQEPAG33UAYTTR526P63P7HIPEXPJXVCQKB",
  ROUTER_ID: "CDNQIEPDPXERUSA3NT7XOY7TTO2DDQLJN2QHDQF5WECYT2I7VDUDMJJP",
  TOKEN_XLM: "CDLZFC3SYJYDZT7K67VZ75HPJVIEUVNIXF47ZG2FB2RMQQVU2HHGCYSC",
  // Live folio basket (self-issued) — mint/redeem path.
  TOKEN_TSTAQUA: "CBGN3EZONL2CJK4342UBBMNVTQRX2DD6QSE45EKEGCYHCE5W76CTV37L",
  TOKEN_TSTVELO: "CCKCOVTJ7V3VXZYUJXMNQZT6O5JEX6CKCGXW3HCJSIYMTLAX2K6E5Z3T",
  TOKEN_TSTUSDC: "CAK7ZU7IWDNJWB5W4F73RDNAYQMO5DVHDNGL5NLUYCGWTYDWF444VMX7",
  TOKEN_TSTEURC: "CAHXEUFDYCQ6GHFXL52CFSPAOMYIJHFDHN7B2NO6ZRRXFRNLLSHMYJXX",
  // Real Aquarius testnet SACs used by the Pools page (live liquidity).
  TOKEN_AQUA: "CDNVQW44C3HALYNVQ4SOBXY5EWYTGVYXX6JPESOLQDABJI5FC5LTRRUE",
  TOKEN_AQUA_USDC: "CAZRY5GSFBFXD7H6GAFBA5YGYQTDXU4QKWKMYFWBAZFUCURN3WKX6LF5",
  TOKEN_AQUA_USDT: "CBL6KD2LFMLAUKFFWNNXWOXFN73GAXLEA4WMJRLQ5L76DMYTM3KWQVJN",
  TOKEN_AQUA_BTC: "CBSXOAE7GAW7Y3CHTNZ3D4GLB6KI43MC36DY7GTZN4AGI7AWQ5V55YIQ",
  // Pool-index hashes from amm-api-testnet.aqua.network (verified get_reserves).
  POOL_AQUA_XLM: "9ac7a9cde23ac2ada11105eeaa42e43c2ea8332ca0aa8f41f58d7160274d718e",
  POOL_USDC_XLM: "9ac7a9cde23ac2ada11105eeaa42e43c2ea8332ca0aa8f41f58d7160274d718e",
  POOL_USDT_XLM: "ed45429155f876475d3c7ac18d34273d638d6a5b2fcc736db36d71a5788852c5",
  POOL_BTC_XLM: "24f9c991c44acf33fff5f44031c40385d235dc212d7379e824ba3db1c35371f3",
};

function publicEnv(value: string | undefined, fallback: string): string {
  return value?.trim() || fallback;
}

export const NETWORK_PASSPHRASE = publicEnv(
  process.env.NEXT_PUBLIC_NETWORK_PASSPHRASE,
  CURRENT_TESTNET.NETWORK_PASSPHRASE,
);
export const RPC_URL = publicEnv(process.env.NEXT_PUBLIC_RPC_URL, CURRENT_TESTNET.RPC_URL);
export const HORIZON_URL = publicEnv(
  process.env.NEXT_PUBLIC_HORIZON_URL,
  CURRENT_TESTNET.HORIZON_URL,
);
export const AQUARIUS_ID = publicEnv(
  process.env.NEXT_PUBLIC_AQUARIUS_ID,
  CURRENT_TESTNET.AQUARIUS_ID,
);
export const AQUARIUS_API =
  process.env.NEXT_PUBLIC_AQUARIUS_API?.trim() ||
  "https://amm-api-testnet.aqua.network/api/external/v2";
export const FOLIO_ID = publicEnv(process.env.NEXT_PUBLIC_FOLIO_ID, CURRENT_TESTNET.FOLIO_ID);
export const ROUTER_ID = publicEnv(process.env.NEXT_PUBLIC_ROUTER_ID, CURRENT_TESTNET.ROUTER_ID);

/** Native XLM SAC — the single-asset deposit / pool hub. */
export const XLM_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_XLM,
  CURRENT_TESTNET.TOKEN_XLM,
);

const TSTAQUA_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_TSTAQUA,
  CURRENT_TESTNET.TOKEN_TSTAQUA,
);
const TSTVELO_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_TSTVELO,
  CURRENT_TESTNET.TOKEN_TSTVELO,
);
const TSTUSDC_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_TSTUSDC,
  CURRENT_TESTNET.TOKEN_TSTUSDC,
);
const TSTEURC_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_TSTEURC,
  CURRENT_TESTNET.TOKEN_TSTEURC,
);

const AQUA_TOKEN = publicEnv(process.env.NEXT_PUBLIC_TOKEN_AQUA, CURRENT_TESTNET.TOKEN_AQUA);
const AQUA_USDC_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_AQUA_USDC,
  CURRENT_TESTNET.TOKEN_AQUA_USDC,
);
const AQUA_USDT_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_AQUA_USDT,
  CURRENT_TESTNET.TOKEN_AQUA_USDT,
);
const AQUA_BTC_TOKEN = publicEnv(
  process.env.NEXT_PUBLIC_TOKEN_AQUA_BTC,
  CURRENT_TESTNET.TOKEN_AQUA_BTC,
);

/**
 * Live Aquarius XLM-hub pools on testnet (discovered via
 * amm-api-testnet.aqua.network + on-chain get_reserves).
 *
 * `poolIndex` is the Aquarius pool-index hash (fee tier / type) — may repeat
 * across different token pairs. `key` must be unique (we use the paired SAC).
 */
export const POOLS = [
  {
    key: "aqua-xlm",
    pair: "AQUA / XLM",
    poolIndex: publicEnv(process.env.NEXT_PUBLIC_POOL_AQUA_XLM, CURRENT_TESTNET.POOL_AQUA_XLM),
    token: AQUA_TOKEN,
  },
  {
    key: "usdc-xlm",
    pair: "USDC / XLM",
    poolIndex: publicEnv(process.env.NEXT_PUBLIC_POOL_USDC_XLM, CURRENT_TESTNET.POOL_USDC_XLM),
    token: AQUA_USDC_TOKEN,
  },
  {
    key: "usdt-xlm",
    pair: "USDT / XLM",
    poolIndex: publicEnv(process.env.NEXT_PUBLIC_POOL_USDT_XLM, CURRENT_TESTNET.POOL_USDT_XLM),
    token: AQUA_USDT_TOKEN,
  },
  {
    key: "btc-xlm",
    pair: "BTC / XLM",
    poolIndex: publicEnv(process.env.NEXT_PUBLIC_POOL_BTC_XLM, CURRENT_TESTNET.POOL_BTC_XLM),
    token: AQUA_BTC_TOKEN,
  },
];

/**
 * Classic (non-native) assets in the *folio basket* — each requires the holder
 * to establish a trustline before they can receive it. XLM is native.
 * Still OSMO self-issued tst* until a folio redeploy moves to Aquarius assets.
 */
export const TRUSTLINE_ASSETS = [
  {
    code: "tstAQUA",
    issuer: publicEnv(process.env.NEXT_PUBLIC_TEST_ISSUER, CURRENT_TESTNET.TEST_ISSUER),
  },
  {
    code: "tstVELO",
    issuer: publicEnv(process.env.NEXT_PUBLIC_TEST_ISSUER, CURRENT_TESTNET.TEST_ISSUER),
  },
  {
    code: "tstUSDC",
    issuer: publicEnv(process.env.NEXT_PUBLIC_TEST_ISSUER, CURRENT_TESTNET.TEST_ISSUER),
  },
  {
    code: "tstEURC",
    issuer: publicEnv(process.env.NEXT_PUBLIC_TEST_ISSUER, CURRENT_TESTNET.TEST_ISSUER),
  },
];

/** Aquarius-issued classic assets (for trustlines when swapping on Aquarius). */
export const AQUARIUS_TRUSTLINE_ASSETS = [
  {
    code: "AQUA",
    issuer: publicEnv(
      process.env.NEXT_PUBLIC_AQUARIUS_TEST_ISSUER,
      CURRENT_TESTNET.AQUARIUS_TEST_ISSUER,
    ),
  },
  {
    code: "USDC",
    issuer: publicEnv(
      process.env.NEXT_PUBLIC_AQUARIUS_TEST_ISSUER,
      CURRENT_TESTNET.AQUARIUS_TEST_ISSUER,
    ),
  },
  {
    code: "USDT",
    issuer: publicEnv(
      process.env.NEXT_PUBLIC_AQUARIUS_TEST_ISSUER,
      CURRENT_TESTNET.AQUARIUS_TEST_ISSUER,
    ),
  },
  {
    code: "BTC",
    issuer: publicEnv(
      process.env.NEXT_PUBLIC_AQUARIUS_TEST_ISSUER,
      CURRENT_TESTNET.AQUARIUS_TEST_ISSUER,
    ),
  },
];

/** TESTNET ONLY - see .env.example for why this is safe to ship client-side here. */
export const TEST_ISSUER_SECRET = process.env.NEXT_PUBLIC_TEST_ISSUER_SECRET ?? "";

/** One drip's worth of each asset, in whole-token units (not stroops/units). */
export const FAUCET_AMOUNTS: Record<string, string> = {
  XLM: "20",
  tstAQUA: "1000000",
  tstVELO: "10000",
  tstUSDC: "1000",
  tstEURC: "1000",
};

/**
 * Display metadata per underlying token (SAC contract id -> info).
 */
export const TOKEN_INFO: Record<string, { symbol: string; color: string; simulated?: boolean }> = {
  [XLM_TOKEN]: { symbol: "XLM", color: "#7b68ee" },
  [TSTAQUA_TOKEN]: { symbol: "tstAQUA", color: "#9f4ef5" },
  [TSTVELO_TOKEN]: { symbol: "tstVELO", color: "#f5a623", simulated: true },
  [TSTUSDC_TOKEN]: { symbol: "tstUSDC", color: "#2775ca" },
  [TSTEURC_TOKEN]: { symbol: "tstEURC", color: "#1a9c6b" },
  [AQUA_TOKEN]: { symbol: "AQUA", color: "#00a3ff" },
  [AQUA_USDC_TOKEN]: { symbol: "USDC", color: "#2775ca" },
  [AQUA_USDT_TOKEN]: { symbol: "USDT", color: "#26a17b" },
  [AQUA_BTC_TOKEN]: { symbol: "BTC", color: "#f7931a" },
};

export const SHARE_DECIMALS = 7;
export const PRICE_DECIMALS = 14;
