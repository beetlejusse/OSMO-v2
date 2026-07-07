# Nebula DTF - one-shot testnet setup. ASCII only: PS 5.1 reads BOM-less files as ANSI.
# Issues clearly-named test tokens, deploys the whole contract stack, creates
# the Stellar Ecosystem Folio and bootstraps it with a ratio-correct deposit.
#
# Test-token naming (ADR-012, revised 2026-07-06): tst<CODE>, each mimicking a
# real Stellar asset whose PRICE is relayed live from mainnet Reflector
# (see price-relay.ps1) - a testnet contract can never call a mainnet
# contract on-chain, so instead an off-chain read here feeds our own testnet
# MockPriceFeed. XLM uses the REAL native testnet asset (friendbot-funded).
#   tstAQUA -> AQUA (aqua.network, live Reflector price)
#   tstEURC -> EURC (Circle, live Reflector price)
#   tstUSDC -> USDC (Circle, fixed $1.00 - it's this oracle's own base asset)
#   tstVELO -> VELO (velo.org, NOT covered by Reflector - simulated placeholder)
#
# Run once. Requires: stellar CLI on PATH, wasm built (scripts\test.ps1).

$ErrorActionPreference = "Stop"
$Network = "testnet"
. "$PSScriptRoot\price-relay.ps1"

function Invoke-Stellar {
    # local EAP: CLI logs status to stderr; under Stop + any redirection those
    # lines become terminating NativeCommandErrors on PS 5.1
    $ErrorActionPreference = "Continue"
    & stellar @args
    if ($LASTEXITCODE -ne 0) { throw "stellar $($args -join ' ') failed" }
}

Write-Host "== 1. Identities (admin = deployer/oracle admin, issuer = test-token issuer, user = demo user)"
foreach ($name in @("nebula-admin", "nebula-test-issuer", "nebula-user")) {
    # cmd /c: PS 5.1 + ErrorActionPreference Stop turns native stderr into a
    # terminating error when redirected; the CLI logs even successes to stderr.
    # Ignore failure (key already exists on re-run).
    cmd /c "stellar keys generate $name --network $Network --fund 2>nul" | Out-Null
    Write-Host "  $name -> $(& stellar keys address $name)"
}
$admin  = & stellar keys address nebula-admin
$issuer = & stellar keys address nebula-test-issuer
$user   = & stellar keys address nebula-user

Write-Host "== 2. Test tokens: trustlines, SAC deploys"
$codes = @("tstAQUA", "tstVELO", "tstUSDC", "tstEURC")
$sacIds = [ordered]@{}
foreach ($code in $codes) {
    # user must trust the classic asset before SAC can mint to their G-address
    Invoke-Stellar tx new change-trust --source nebula-user --line "${code}:${issuer}" --network $Network
    $sacIds[$code] = (& stellar contract asset deploy --asset "${code}:${issuer}" --source nebula-test-issuer --network $Network)
    if ($LASTEXITCODE -ne 0) {
        # already deployed on a previous run - resolve the existing id
        $sacIds[$code] = (Invoke-Stellar contract id asset --asset "${code}:${issuer}" --network $Network)
    }
    Write-Host "  $code SAC: $($sacIds[$code])"
}
$xlmSac = Invoke-Stellar contract id asset --asset native --network $Network
Write-Host "  XLM (native) SAC: $xlmSac"

Write-Host "== 3. Mint dev balances to nebula-user"
Invoke-Stellar contract invoke --id $sacIds.tstAQUA --source nebula-test-issuer --network $Network '--' mint --to $user --amount 10000000000000   # 1,000,000 tstAQUA
Invoke-Stellar contract invoke --id $sacIds.tstVELO --source nebula-test-issuer --network $Network '--' mint --to $user --amount 100000000000     # 10,000 tstVELO
Invoke-Stellar contract invoke --id $sacIds.tstUSDC --source nebula-test-issuer --network $Network '--' mint --to $user --amount 10000000000      # 1,000 tstUSDC
Invoke-Stellar contract invoke --id $sacIds.tstEURC --source nebula-test-issuer --network $Network '--' mint --to $user --amount 10000000000      # 1,000 tstEURC

Write-Host "== 4. MockPriceFeed, stamped with LIVE mainnet-relayed prices (single feed - DIA dropped)"
$feed = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_mock_price_feed.wasm --source nebula-admin --network $Network '--' --admin $admin --decimals 14
Write-Host "  MockPriceFeed: $feed"

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$live = Get-RelayedPrices
$prices = [ordered]@{
    $xlmSac          = $live.XLM
    $sacIds.tstAQUA  = $live.AQUA
    $sacIds.tstVELO  = $live.VELO
    $sacIds.tstUSDC  = $live.USDC
    $sacIds.tstEURC  = $live.EURC
}
foreach ($id in $prices.Keys) {
    # literal \" so Windows native arg parsing delivers real quotes to the CLI
    $assetJson = '{\"Stellar\":\"' + $id + '\"}'
    Invoke-Stellar contract invoke --id $feed --source nebula-admin --network $Network '--' set_price --asset $assetJson --price $prices[$id] --timestamp $now
}

Write-Host "== 5. OracleRouter v2 (single real feed per token; max_age 24h for dev;"
Write-Host "      re-relay via scripts\refresh-prices.ps1 when it goes stale)"
$router = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_oracle_router.wasm --source nebula-admin --network $Network '--' --admin $admin --max_age_secs 86400 --max_divergence_bps 500 --allow_single true
Write-Host "  OracleRouter: $router"
foreach ($id in $prices.Keys) {
    $assetJson = '{\"Stellar\":\"' + $id + '\"}'
    $feedsJson = '[[\"' + $feed + '\",' + $assetJson + ']]'
    Invoke-Stellar contract invoke --id $router --source nebula-admin --network $Network '--' set_feeds --token $id --feeds $feedsJson
}

Write-Host "== 6. Factory + Stellar Ecosystem Folio (XLM 40 / tstAQUA 20 / tstVELO 15 / tstUSDC 15 / tstEURC 10)"
$wasmHash = Invoke-Stellar contract upload --wasm target\wasm32v1-none\release\nebula_folio.wasm --source nebula-admin --network $Network
$factory = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_factory.wasm --source nebula-admin --network $Network '--' --admin $admin --folio_wasm_hash $wasmHash
Write-Host "  Factory: $factory"

$salt = -join ((1..64) | ForEach-Object { "{0:x}" -f (Get-Random -Max 16) })
$ids = @($xlmSac, $sacIds.tstAQUA, $sacIds.tstVELO, $sacIds.tstUSDC, $sacIds.tstEURC)
$weightsBps = @(4000, 2000, 1500, 1500, 1000)
$folioTokens  = '[\"' + ($ids -join '\",\"') + '\"]'
$folioWeights = "[" + ($weightsBps -join ",") + "]"
$folio = Invoke-Stellar contract invoke --id $factory --source nebula-admin --network $Network '--' create_folio `
    --salt $salt --folio_admin $admin --router $router `
    --name "Stellar Ecosystem Folio" --symbol "SEF" `
    --tokens $folioTokens --weights_bps $folioWeights
$folio = $folio.Trim('"')
Write-Host "  Folio (SEF): $folio"

Write-Host "== 7. Bootstrap: ~`$100 at target ratio, deposit amounts computed from the live prices above"
# deposit_units (7-dec) = TOTAL_USD * weight_bps * 10^17 / price_14dec  (see DECISION_LOG for derivation)
$TOTAL_USD = [bigint]100
$TEN17 = [bigint]::Parse("100000000000000000")
$priceList = @($live.XLM, $live.AQUA, $live.VELO, $live.USDC, $live.EURC)
$deposits = for ($i = 0; $i -lt $ids.Length; $i++) {
    $price = [bigint]::Parse($priceList[$i])
    $weight = [bigint]$weightsBps[$i]
    (($TOTAL_USD * $weight * $TEN17) / $price).ToString()
}
Write-Host "  Deposits (7-dec units): $($deposits -join ', ')"
$depositsJson = '[\"' + ($deposits -join '\",\"') + '\"]'
Invoke-Stellar contract invoke --id $folio --source nebula-user --network $Network '--' init_mint --user $user --deposits $depositsJson
Invoke-Stellar contract invoke --id $folio --source nebula-user --network $Network '--' nav

Write-Host ""
Write-Host "== DONE. Addresses (also written to .stellar\nebula-testnet.json):"
$out = [ordered]@{
    network = $Network; admin = $admin; issuer = $issuer; user = $user
    xlm_sac = $xlmSac; mock_feed = $feed
    router = $router; factory = $factory; folio_sef = $folio
}
foreach ($code in $codes) { $out["sac_$($code.ToLower())"] = $sacIds[$code] }
New-Item -ItemType Directory -Force .stellar | Out-Null
$out | ConvertTo-Json | Out-File -Encoding utf8 .stellar\nebula-testnet.json
$out | Format-Table
