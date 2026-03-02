$ErrorActionPreference = 'Stop'

$BuildDir = if ($env:BUILD_DIR) { $env:BUILD_DIR } else { 'build' }
$BuildType = if ($env:BUILD_TYPE) { $env:BUILD_TYPE } else { 'Release' }
$PackageDir = if ($env:PACKAGE_DIR) { $env:PACKAGE_DIR } else { 'dist' }
$Generator = if ($env:CMAKE_GENERATOR) { $env:CMAKE_GENERATOR } else { 'Visual Studio 17 2022' }
$Architecture = if ($env:CMAKE_ARCH) { $env:CMAKE_ARCH } else { 'x64' }

if (-not $env:LLVM_DIR) {
  $Candidate = 'C:\Program Files\LLVM\lib\cmake\llvm'
  if (Test-Path $Candidate) {
    $env:LLVM_DIR = $Candidate
  }
}

cmake -S . -B $BuildDir -G $Generator -A $Architecture -DLUNE_BUILD_TESTS=ON -DLLVM_DIR="$env:LLVM_DIR"
if ($LASTEXITCODE -ne 0) { throw 'cmake configure failed' }

cmake --build $BuildDir --config $BuildType
if ($LASTEXITCODE -ne 0) { throw 'cmake build failed' }

ctest --test-dir $BuildDir -C $BuildType --output-on-failure
if ($LASTEXITCODE -ne 0) { throw 'ctest failed' }

New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

$ExeCandidates = @(
  "$BuildDir/$BuildType/lune.exe",
  "$BuildDir/lune.exe"
)
$ExePath = $ExeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ExePath) {
  throw 'Could not locate lune.exe after build'
}

Copy-Item $ExePath "$PackageDir/lune-windows-x64.exe"
Compress-Archive -Path "$PackageDir/lune-windows-x64.exe" -DestinationPath "$PackageDir/lune-windows-x64.zip" -Force
Write-Output "Built artifact: $PackageDir/lune-windows-x64.zip"
