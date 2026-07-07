# Re-stamp our testnet MockPriceFeed with live mainnet prices (relayed - see
# price-relay.ps1) so the router's staleness guard keeps passing during dev.
# Reads contract addresses from .stellar\nebula-testnet.json.
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\price-relay.ps1"

$cfg = Get-Content .stellar\nebula-testnet.json | ConvertFrom-Json
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$prices = Get-RelayedPrices

$byToken = [ordered]@{
    $cfg.xlm_sac    = $prices.XLM
    $cfg.sac_tstaqua = $prices.AQUA
    $cfg.sac_tstvelo = $prices.VELO
    $cfg.sac_tstusdc = $prices.USDC
    $cfg.sac_tsteurc = $prices.EURC
}
foreach ($id in $byToken.Keys) {
    $assetJson = '{\"Stellar\":\"' + $id + '\"}'
    $ErrorActionPreference = "Continue"
    & stellar contract invoke --id $cfg.mock_feed --source nebula-admin --network $cfg.network '--' set_price --asset $assetJson --price $byToken[$id] --timestamp $now
    if ($LASTEXITCODE -ne 0) { throw "set_price failed for $id" }
}
Write-Host "Testnet feed refreshed at $now with live-relayed mainnet prices"
