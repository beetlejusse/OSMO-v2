# Build wasm first (factory tests contractimport! the folio wasm), then test.
$ErrorActionPreference = "Stop"
& stellar contract build
if ($LASTEXITCODE -ne 0) { throw "wasm build failed" }
& cargo test --workspace
if ($LASTEXITCODE -ne 0) { throw "tests failed" }
