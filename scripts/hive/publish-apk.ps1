<#
  Puts a Hive test APK on this repo's "test-apk" release, ENCRYPTED, for the agent-testers workflow.

    powershell -ExecutionPolicy Bypass -File scripts\hive\publish-apk.ps1 -Apk D:\pp-run\hive-test.apk

  The repo is public, so the APK must not be downloadable as it is. This script:
   1. makes a new random passphrase in memory (never printed, never written to disk),
   2. saves it as the APK_PASSPHRASE Actions secret (the workflow decrypts with it),
   3. encrypts the APK with it (openssl AES-256-CBC, PBKDF2, the same scheme the workflow uses),
   4. replaces the release's hive-test.apk.enc and removes any unencrypted hive-test.apk.

  Run it yourself, in your own terminal: the passphrase never passes through Claude.
#>
param([Parameter(Mandatory = $true)][string]$Apk)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }
$repo = (gh repo view --json nameWithOwner --jq .nameWithOwner)
if (-not $repo) { throw "Run this from inside the testers repo folder." }

$openssl = (Get-Command openssl -ErrorAction SilentlyContinue).Source
if (-not $openssl) {
  $candidate = 'C:\Program Files\Git\usr\bin\openssl.exe'
  if (Test-Path $candidate) { $openssl = $candidate } else { throw "openssl not found: install Git for Windows." }
}

# 1. A 32-byte random passphrase, hex, in memory only.
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$env:HIVE_APK_PASS = ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""

try {
  # 2. The secret the workflow reads.
  $env:HIVE_APK_PASS | gh secret set APK_PASSPHRASE --repo $repo
  if ($LASTEXITCODE -ne 0) { throw "Could not set the APK_PASSPHRASE secret." }

  # 3. Encrypt next to a temp file, never beside the source APK.
  $out = Join-Path $env:TEMP 'hive-test.apk.enc'
  & $openssl enc -aes-256-cbc -pbkdf2 -salt -in $Apk -out $out -pass env:HIVE_APK_PASS
  if ($LASTEXITCODE -ne 0) { throw "openssl failed." }

  # 4. Upload the encrypted file; drop any unencrypted copy from the release.
  gh release view test-apk --repo $repo *> $null
  if ($LASTEXITCODE -ne 0) {
    gh release create test-apk --repo $repo --title "Hive test APK (encrypted)" --notes "Encrypted Hive test APK for the agent-testers workflow."
  }
  gh release upload test-apk $out --repo $repo --clobber
  if ($LASTEXITCODE -ne 0) { throw "Upload failed." }
  Remove-Item $out -Force
  # An unencrypted copy from before must not stay on a public release. Absent is fine.
  $names = gh release view test-apk --repo $repo --json assets --jq '.assets[].name'
  if ($names -contains 'hive-test.apk') { gh release delete-asset test-apk hive-test.apk --repo $repo --yes }
  Write-Host "Done: encrypted APK uploaded and APK_PASSPHRASE set for $repo."
} finally {
  Remove-Item Env:\HIVE_APK_PASS -ErrorAction SilentlyContinue
}
