# Shared price-sourcing logic (ASCII only, PS 5.1 - see setup-testnet.ps1 header notes).
# Dot-source this file, then call Get-RelayedPrices $cfg.
#
# Testnet contracts can never call mainnet contracts (separate ledgers, no
# shared execution - not a Soroban config option). So instead of finding a
# "live" testnet oracle, we read real prices from mainnet Reflector's public
# Stellar Pubnet Pulse Oracle (free, no invocation fee, 5-min updates) with a
# plain read-only CLI call, and hand them back as testnet-ready 14-decimal
# i128 strings for the caller to write into our own testnet MockPriceFeed.

$MAINNET_ORACLE = "CALI2BYU2JE6WVRUFYTS6MSBNEHGJ35P4AVCZYF3B6QOE3QKOB2PLE6M"
$MAINNET_RPC = "https://mainnet.sorobanrpc.com"
$MAINNET_PASSPHRASE = "Public Global Stellar Network ; September 2015"

# Mainnet SAC addresses for the real assets our test tokens mimic (computed via
# `stellar contract id asset`, cross-checked live against the oracle 2026-07-06).
$MAINNET_ASSET = @{
    XLM  = "CAS3J7GYLGXMF6TDJBBYYSE3HQ6BBSMLNUQ34T6TZMYMW2EVH34XOWMA"
    AQUA = "CAUIKL3IYGMERDRUN6YSCLWVAKIFG5Q4YJHUKM4S4NJZQIA3BAS6OJPK"
    EURC = "CDTKPWPLOURQA2SGTKTUQOWRCBZEORB4BWBOMJ3D3ZTQQSGE5F6JBQLV"
}

function Get-MainnetPrice($assetAddress) {
    $ErrorActionPreference = "Continue"
    $assetJson = '{\"Stellar\":\"' + $assetAddress + '\"}'
    $raw = & stellar contract invoke --id $MAINNET_ORACLE --source nebula-admin `
        --rpc-url $MAINNET_RPC --network-passphrase $MAINNET_PASSPHRASE --send=no `
        '--' lastprice --asset $assetJson 2>$null
    $json = $raw | Select-Object -Last 1 | ConvertFrom-Json
    if (-not $json.price) { throw "no mainnet price returned for $assetAddress" }
    return $json.price
}

# Returns @{ XLM = "...", AQUA = "...", EURC = "...", USDC = "...", VELO = "..." }
# every value a 14-decimal i128 string, ready for MockPriceFeed.set_price.
function Get-RelayedPrices {
    $prices = [ordered]@{
        XLM  = Get-MainnetPrice $MAINNET_ASSET.XLM
        AQUA = Get-MainnetPrice $MAINNET_ASSET.AQUA
        EURC = Get-MainnetPrice $MAINNET_ASSET.EURC
        # USDC is this oracle's own base/numeraire asset (confirmed via base()),
        # so it has no lastprice entry - it's $1.00 by definition, 14 decimals.
        USDC = "100000000000000"
        # ponytail: VELO has no Reflector coverage under either known issuer
        # (checked both live 2026-07-06, both null) - static placeholder until
        # a real feed exists. Revisit if Reflector/DIA ever add it.
        VELO = "2000000000000"
    }
    Write-Host "Relayed live mainnet prices: XLM=$($prices.XLM) AQUA=$($prices.AQUA) EURC=$($prices.EURC) USDC=$($prices.USDC) VELO(sim)=$($prices.VELO)"
    return $prices
}
