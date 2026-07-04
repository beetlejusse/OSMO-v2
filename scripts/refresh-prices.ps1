# Re-stamp mock feed prices with the current time so the router's staleness
# guard passes during dev. Reads addresses from .stellar\nebula-testnet.json.
$ErrorActionPreference = "Stop"
$cfg = Get-Content .stellar\nebula-testnet.json | ConvertFrom-Json
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

$prices = @{
    $cfg.xlm_sac   = "40000000000000"
    $cfg.sac_taqua = "40000000000"
    $cfg.sac_tvelo = "2000000000000"
    $cfg.sac_tusdc = "100000000000000"
    $cfg.sac_teurc = "108000000000000"
}
$feeds = @($cfg.mock_feed)
if ($cfg.mock_feed_dia) { $feeds += $cfg.mock_feed_dia }
foreach ($f in $feeds) {
    foreach ($id in $prices.Keys) {
        $assetJson = '{\"Stellar\":\"' + $id + '\"}'
        & stellar contract invoke --id $f --source nebula-admin --network $cfg.network -- set_price --asset $assetJson --price $prices[$id] --timestamp $now
        if ($LASTEXITCODE -ne 0) { throw "set_price failed for $id on $f" }
    }
}
Write-Host "Prices refreshed at $now"
