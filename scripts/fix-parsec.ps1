# Fix Parsec IPv6 connectivity in Clash Verge Rev TUN mode
# Run as Administrator if modifying system proxy settings

$ErrorActionPreference = "Stop"

$scriptOverride = @'
function main(config, profileName) {
  // Exclude Parsec processes from TUN capture
  if (!config.tun) config.tun = {};
  if (!config.tun["exclude-process"]) config.tun["exclude-process"] = [];

  var parsecProcs = ["parsecd.exe", "parsec.exe", "parsec-bootstrap.exe"];
  for (var i = 0; i < parsecProcs.length; i++) {
    if (config.tun["exclude-process"].indexOf(parsecProcs[i]) === -1) {
      config.tun["exclude-process"].push(parsecProcs[i]);
    }
  }

  // Preserve real DNS for Parsec domains
  if (!config.dns) config.dns = {};
  if (!config.dns["fake-ip-filter"]) config.dns["fake-ip-filter"] = [];

  var parsecDomains = ["+.parsec.app", "+.parsecgaming.com", "+.parsec.gg"];
  for (var i = 0; i < parsecDomains.length; i++) {
    if (config.dns["fake-ip-filter"].indexOf(parsecDomains[i]) === -1) {
      config.dns["fake-ip-filter"].push(parsecDomains[i]);
    }
  }

  return config;
}
'@

# Find Clash Verge Rev profiles directory
$profileDirs = @(
    "$env:APPDATA\io.github.clash-verge-rev.clash-verge-rev\profiles",
    "$env:APPDATA\clash-verge-rev\profiles",
    "$env:USERPROFILE\.config\clash-verge-rev\profiles"
)

$foundDir = $null
foreach ($dir in $profileDirs) {
    if (Test-Path $dir) {
        $foundDir = $dir
        break
    }
}

if (-not $foundDir) {
    Write-Host "❌ Clash Verge Rev profiles directory not found" -ForegroundColor Red
    Write-Host "Searched locations:"
    $profileDirs | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

Write-Host "✓ Found profiles directory: $foundDir" -ForegroundColor Green

# Find active script files
$jsFiles = Get-ChildItem -Path $foundDir -Filter "*.js" -ErrorAction SilentlyContinue

if ($jsFiles.Count -eq 0) {
    Write-Host "⚠ No JavaScript override files found" -ForegroundColor Yellow
    Write-Host "Creating new script: parsec-fix.js"
    $targetFile = Join-Path $foundDir "parsec-fix.js"
} else {
    Write-Host "Found script files:"
    for ($i = 0; $i -lt $jsFiles.Count; $i++) {
        Write-Host "  [$i] $($jsFiles[$i].Name)"
    }

    $choice = Read-Host "Select script to modify (0-$($jsFiles.Count-1)) or 'n' to create new"

    if ($choice -eq 'n') {
        $targetFile = Join-Path $foundDir "parsec-fix.js"
    } else {
        $targetFile = $jsFiles[[int]$choice].FullName
    }
}

# Backup existing file
if (Test-Path $targetFile) {
    $backup = "$targetFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $targetFile $backup
    Write-Host "✓ Backed up to: $backup" -ForegroundColor Green
}

# Write new script
$scriptOverride | Out-File -FilePath $targetFile -Encoding UTF8
Write-Host "✓ Applied fix to: $targetFile" -ForegroundColor Green

Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Clash Verge Rev"
Write-Host "  2. Go to Profiles → select your active profile"
Write-Host "  3. Set Script Override to: $(Split-Path $targetFile -Leaf)"
Write-Host "  4. Reload configuration or restart TUN mode"
Write-Host "`n🎮 Parsec should now connect via IPv6!"
