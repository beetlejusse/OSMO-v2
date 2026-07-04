# Nebula DTF - one-shot testnet setup. ASCII only: PS 5.1 reads BOM-less files as ANSI.
# Issues clearly-named test tokens, deploys the whole contract stack, creates
# the Stellar Ecosystem Folio and bootstraps it with a ratio-correct deposit.
#
# Test-token naming (ADR-012): T<code> = "Test <code>", each mimicking a real
# Stellar asset. XLM uses the REAL native testnet asset (friendbot-funded).
#   TAQUA -> AQUA (aqua.network)   TVELO -> VELO (velo.org)
#   TUSDC -> USDC (Circle)         TEURC -> EURC (Circle)
#
# Run once. Requires: stellar CLI on PATH, wasm built (scripts\test.ps1).

$ErrorActionPreference = "Stop"
$Network = "testnet"

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
# mimicked asset -> [code, mock USD price at 14 decimals]
$tokens = [ordered]@{
    TAQUA = "40000000000"        # $0.0004  (AQUA)
    TVELO = "2000000000000"      # $0.02    (VELO)
    TUSDC = "100000000000000"    # $1.00    (USDC)
    TEURC = "108000000000000"    # $1.08    (EURC)
}
$sacIds = [ordered]@{}
foreach ($code in $tokens.Keys) {
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
Invoke-Stellar contract invoke --id $sacIds.TAQUA --source nebula-test-issuer --network $Network '--' mint --to $user --amount 10000000000000   # 1,000,000 TAQUA
Invoke-Stellar contract invoke --id $sacIds.TVELO --source nebula-test-issuer --network $Network '--' mint --to $user --amount 100000000000     # 10,000 TVELO
Invoke-Stellar contract invoke --id $sacIds.TUSDC --source nebula-test-issuer --network $Network '--' mint --to $user --amount 10000000000      # 1,000 TUSDC
Invoke-Stellar contract invoke --id $sacIds.TEURC --source nebula-test-issuer --network $Network '--' mint --to $user --amount 10000000000      # 1,000 TEURC

Write-Host "== 4. Mock price feeds x2 (primary = Reflector stand-in, secondary = DIA stand-in;"
Write-Host "      test tokens aren't on Reflector. XLM could use the real Reflector testnet feed"
Write-Host "      CAVLP5DH2GJPZMVO7IJY4CVOD5MWEFTJFVPD2YY2FQXOQHRGHK4D6HLP - mock keeps dev deterministic)"
$feed = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_mock_price_feed.wasm --source nebula-admin --network $Network '--' --admin $admin --decimals 14
$feedDia = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_mock_price_feed.wasm --source nebula-admin --network $Network '--' --admin $admin --decimals 14
Write-Host "  MockPriceFeed (primary): $feed"
Write-Host "  MockPriceFeed (DIA stand-in): $feedDia"

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$prices = [ordered]@{ $xlmSac = "40000000000000" }   # XLM $0.40
foreach ($code in $tokens.Keys) { $prices[$sacIds[$code]] = $tokens[$code] }
foreach ($id in $prices.Keys) {
    # literal \" so Windows native arg parsing delivers real quotes to the CLI
    $assetJson = '{\"Stellar\":\"' + $id + '\"}'
    Invoke-Stellar contract invoke --id $feed --source nebula-admin --network $Network '--' set_price --asset $assetJson --price $prices[$id] --timestamp $now
    Invoke-Stellar contract invoke --id $feedDia --source nebula-admin --network $Network '--' set_price --asset $assetJson --price $prices[$id] --timestamp $now
}

Write-Host "== 5. OracleRouter v2 (median of 2 feeds, 5% divergence breaker, allow_single;"
Write-Host "      max_age 24h for dev; prices refresh via scripts\refresh-prices.ps1)"
$router = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_oracle_router.wasm --source nebula-admin --network $Network '--' --admin $admin --max_age_secs 86400 --max_divergence_bps 500 --allow_single true
Write-Host "  OracleRouter: $router"
foreach ($id in $prices.Keys) {
    $assetJson = '{\"Stellar\":\"' + $id + '\"}'
    $feedsJson = '[[\"' + $feed + '\",' + $assetJson + '],[\"' + $feedDia + '\",' + $assetJson + ']]'
    Invoke-Stellar contract invoke --id $router --source nebula-admin --network $Network '--' set_feeds --token $id --feeds $feedsJson
}

Write-Host "== 6. Factory + Stellar Ecosystem Folio (XLM 40 / TAQUA 20 / TVELO 15 / TUSDC 15 / TEURC 10)"
$wasmHash = Invoke-Stellar contract upload --wasm target\wasm32v1-none\release\nebula_folio.wasm --source nebula-admin --network $Network
$factory = Invoke-Stellar contract deploy --wasm target\wasm32v1-none\release\nebula_factory.wasm --source nebula-admin --network $Network '--' --admin $admin --folio_wasm_hash $wasmHash
Write-Host "  Factory: $factory"

$salt = -join ((1..64) | ForEach-Object { "{0:x}" -f (Get-Random -Max 16) })
$ids = @($xlmSac, $sacIds.TAQUA, $sacIds.TVELO, $sacIds.TUSDC, $sacIds.TEURC)
$folioTokens  = '[\"' + ($ids -join '\",\"') + '\"]'
$folioWeights = "[4000,2000,1500,1500,1000]"
$folio = Invoke-Stellar contract invoke --id $factory --source nebula-admin --network $Network '--' create_folio `
    --salt $salt --folio_admin $admin --router $router `
    --name "Stellar Ecosystem Folio" --symbol "SEF" `
    --tokens $folioTokens --weights_bps $folioWeights
$folio = $folio.Trim('"')
Write-Host "  Folio (SEF): $folio"

Write-Host "== 7. Bootstrap: ~`$100 at target ratio from nebula-user"
# $40 XLM=100, $20 TAQUA=50k, $15 TVELO=750, $15 TUSDC=15, $10 TEURC~=9.259
$deposits = '[\"1000000000\",\"500000000000\",\"7500000000\",\"150000000\",\"92590000\"]'
Invoke-Stellar contract invoke --id $folio --source nebula-user --network $Network '--' init_mint --user $user --deposits $deposits
Invoke-Stellar contract invoke --id $folio --source nebula-user --network $Network '--' nav

Write-Host ""
Write-Host "== DONE. Addresses (also written to .stellar\nebula-testnet.json):"
$out = [ordered]@{
    network = $Network; admin = $admin; issuer = $issuer; user = $user
    xlm_sac = $xlmSac; mock_feed = $feed; mock_feed_dia = $feedDia
    router = $router; factory = $factory; folio_sef = $folio
}
foreach ($code in $tokens.Keys) { $out["sac_$($code.ToLower())"] = $sacIds[$code] }
New-Item -ItemType Directory -Force .stellar | Out-Null
$out | ConvertTo-Json | Out-File -Encoding utf8 .stellar\nebula-testnet.json
$out | Format-Table
