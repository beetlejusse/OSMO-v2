# Seeds Soroswap testnet liquidity pools, XLM as the hub for every pair (see
# docs/IMPLEMENTATION_PLAN.md SS2.4 - the exchange token is always XLM, so
# every pool is an XLM/<asset> pair, never asset/asset directly). Uses the
# real, unmodified Soroswap Router - no custom AMM contract (rejected in the
# plan doc: create_pair is permissionless and add_liquidity auto-creates a
# missing pair, so seeding real infra beats building a private one).
# Idempotent: skips any pair that already has reserves.

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\price-relay.ps1"

$ROUTER = "CCJUD55AG6W5HAI5LRVNKAE5WDP5XGZBUDS5WNTIVDU7O264UZZE7BRD"
$TARGET_USD_PER_LEG = 100

function Invoke-Stellar {
    $ErrorActionPreference = "Continue"
    & stellar @args
    if ($LASTEXITCODE -ne 0) { throw "stellar $($args -join ' ') failed" }
}

$cfg = Get-Content .stellar\nebula-testnet.json | ConvertFrom-Json
$live = Get-RelayedPrices
$user = & stellar keys address nebula-user

$pools = @(
    @{ code = "tstAQUA"; token = $cfg.sac_tstaqua; price = $live.AQUA }
    @{ code = "tstVELO"; token = $cfg.sac_tstvelo; price = $live.VELO }
    @{ code = "tstUSDC"; token = $cfg.sac_tstusdc; price = $live.USDC }
    @{ code = "tstEURC"; token = $cfg.sac_tsteurc; price = $live.EURC }
)

$deadline = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 300
$TEN7 = [bigint]::Parse("10000000")
$TEN14 = [bigint]::Parse("100000000000000")
$xlmPrice = [bigint]::Parse($live.XLM)

foreach ($p in $pools) {
    Write-Host "== $($p.code) / XLM =="
    $ErrorActionPreference = "Continue"
    $pairAddr = (& stellar contract invoke --id $ROUTER --source nebula-user --network testnet --send=no '--' router_pair_for --token_a $cfg.xlm_sac --token_b $p.token 2>$null | Select-Object -Last 1) -replace '"', ''
    $seeded = $false
    if ($pairAddr) {
        & stellar contract invoke --id $pairAddr --source nebula-user --network testnet --send=no '--' get_reserves 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $seeded = $true }
    }
    $ErrorActionPreference = "Stop"

    if ($seeded) {
        Write-Host "  already seeded (pair $pairAddr) - skipping"
        continue
    }

    # xlm_amount (7-dec) = TARGET_USD * 10^7 * 10^14 / xlm_price_14dec ; same for the asset leg
    $price = [bigint]::Parse($p.price)
    $xlmAmount = ([bigint]$TARGET_USD_PER_LEG * $TEN7 * $TEN14) / $xlmPrice
    $assetAmount = ([bigint]$TARGET_USD_PER_LEG * $TEN7 * $TEN14) / $price
    $xlmMin = [bigint]([double]$xlmAmount * 0.99)
    $assetMin = [bigint]([double]$assetAmount * 0.99)

    Write-Host "  depositing $xlmAmount XLM-units + $assetAmount $($p.code)-units"
    Invoke-Stellar contract invoke --id $ROUTER --source nebula-user --network testnet '--' add_liquidity `
        --token_a $cfg.xlm_sac --token_b $p.token `
        --amount_a_desired $xlmAmount --amount_b_desired $assetAmount `
        --amount_a_min $xlmMin --amount_b_min $assetMin `
        --to $user --deadline $deadline
}

Write-Host ""
Write-Host "Done. View pools at https://testnet.soroswap.finance/pools"
