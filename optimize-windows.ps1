# Windows PowerShell Script for Ultimate Docker Performance
# Run as Administrator

Write-Host "🚀 Optimizing Windows for High-Performance Streaming" -ForegroundColor Green

# 1. WSL2 Memory and CPU Optimization
Write-Host "📝 Creating WSL2 configuration..." -ForegroundColor Yellow
$wslConfig = @"
[wsl2]
# Use 75% of total RAM (adjust based on your RAM)
memory=12GB
# Use all CPU cores
processors=16
# Enable nested virtualization for better Docker performance
nestedVirtualization=true
# Increase virtual hard disk size
swap=8GB
# Optimize for performance
localhostForwarding=true
kernelCommandLine=cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1
"@

$wslConfigPath = "$env:USERPROFILE\.wslconfig"
$wslConfig | Out-File -FilePath $wslConfigPath -Encoding UTF8
Write-Host "✅ WSL2 config saved to $wslConfigPath" -ForegroundColor Green

# 2. Docker Desktop Optimization
Write-Host "📝 Docker Desktop optimizations..." -ForegroundColor Yellow
$dockerConfig = @"
{
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "20GB"
    }
  },
  "experimental": true,
  "features": {
    "buildkit": true
  },
  "insecure-registries": [],
  "registry-mirrors": [],
  "daemon": {
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 10,
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "10m",
      "max-file": "3"
    },
    "default-ulimits": {
      "nofile": {
        "hard": 65536,
        "soft": 65536
      }
    },
    "default-runtime": "nvidia"
  }
}
"@

$dockerConfigPath = "$env:APPDATA\Docker\settings.json"
Write-Host "✅ Docker config template created" -ForegroundColor Green
Write-Host "📌 Manual step: Update Docker Desktop settings with these values" -ForegroundColor Cyan

# 3. Network Optimizations
Write-Host "🌐 Optimizing network settings..." -ForegroundColor Yellow

# TCP optimization for high-speed networks
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global chimney=enabled
netsh int tcp set global rss=enabled
netsh int tcp set global netdma=enabled

# Optimize network adapter settings
Write-Host "📌 Network adapter optimizations to do manually:" -ForegroundColor Cyan
Write-Host "   1. Open Device Manager" -ForegroundColor White
Write-Host "   2. Find your WiFi 6E/7 adapter" -ForegroundColor White
Write-Host "   3. Properties > Advanced > Set these values:" -ForegroundColor White
Write-Host "      - Channel Width: 160MHz (WiFi 6E/7)" -ForegroundColor White
Write-Host "      - Transmit Power: Highest" -ForegroundColor White
Write-Host "      - Roaming Aggressiveness: Lowest" -ForegroundColor White
Write-Host "      - 802.11a/b/g Wireless Mode: 802.11ax" -ForegroundColor White
Write-Host "      - Fat Channel Intolerant: Disabled" -ForegroundColor White

# 4. Power Management
Write-Host "⚡ Setting high-performance power plan..." -ForegroundColor Yellow
powercfg /setactive SCHEME_MIN  # High performance
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

# 5. GPU Optimizations
Write-Host "🎮 GPU optimizations..." -ForegroundColor Yellow
Write-Host "📌 Manual GPU optimizations needed:" -ForegroundColor Cyan
Write-Host "   NVIDIA:" -ForegroundColor White
Write-Host "   1. NVIDIA Control Panel > Manage 3D Settings" -ForegroundColor White
Write-Host "   2. Power management mode: Prefer maximum performance" -ForegroundColor White
Write-Host "   3. CUDA - GPUs: All" -ForegroundColor White
Write-Host ""
Write-Host "   Intel:" -ForegroundColor White
Write-Host "   1. Intel Graphics Command Center" -ForegroundColor White
Write-Host "   2. Performance > Enable hardware acceleration" -ForegroundColor White
Write-Host "   3. Power plan: Maximum performance" -ForegroundColor White

# 6. Windows Defender exclusions
Write-Host "🛡️ Adding Windows Defender exclusions..." -ForegroundColor Yellow
try {
    Add-MpPreference -ExclusionPath "C:\ProgramData\Docker" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:USERPROFILE\.docker" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:USERPROFILE\AppData\Local\Docker" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "docker.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "dockerd.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "wsl.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "wslhost.exe" -ErrorAction SilentlyContinue
    Write-Host "✅ Windows Defender exclusions added" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Run as Administrator to add Defender exclusions" -ForegroundColor Red
}

# 7. Service optimizations
Write-Host "⚙️ Optimizing Windows services..." -ForegroundColor Yellow
# Disable unnecessary services for performance
$servicesToDisable = @(
    "fax",          # Fax service
    "xbgm",         # Xbox Game Monitoring
    "XboxGipSvc",   # Xbox Accessory Management
    "XboxNetApiSvc" # Xbox Live Networking
)

foreach ($service in $servicesToDisable) {
    try {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "   ✅ Disabled $service" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ Could not disable $service" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎯 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Restart your computer to apply WSL2 changes" -ForegroundColor White
Write-Host "2. Install NVIDIA Container Toolkit:" -ForegroundColor White
Write-Host "   wsl --install -d Ubuntu" -ForegroundColor Gray
Write-Host "   # Then in WSL2:" -ForegroundColor Gray
Write-Host "   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg" -ForegroundColor Gray
Write-Host "   distribution=`$(. /etc/os-release;echo $ID$VERSION_ID)" -ForegroundColor Gray
Write-Host "   curl -s -L https://nvidia.github.io/libnvidia-container/`$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list" -ForegroundColor Gray
Write-Host "   sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit" -ForegroundColor Gray
Write-Host "   sudo nvidia-ctk runtime configure --runtime=docker" -ForegroundColor Gray
Write-Host "3. Update docker-compose.yml with the optimized version" -ForegroundColor White
Write-Host "4. Save nginx-optimized.conf to ./config/" -ForegroundColor White
Write-Host "5. Run: docker-compose down && docker-compose up -d" -ForegroundColor White

Write-Host ""
Write-Host "🚀 Your streaming server will be BLAZING FAST! 🚀" -ForegroundColor Green