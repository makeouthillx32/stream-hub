# Real-time Streaming Performance Monitor
# Run this to monitor your streaming server performance

Write-Host "🖥️ STREAMING SERVER PERFORMANCE MONITOR" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

function Get-DockerStats {
    Write-Host "🐳 DOCKER CONTAINER STATS:" -ForegroundColor Green
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    Write-Host ""
}

function Get-NetworkStats {
    Write-Host "🌐 NETWORK PERFORMANCE:" -ForegroundColor Green
    $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.Name -like "*Wi-Fi*" -or $_.Name -like "*Ethernet*"} | Select-Object -First 1
    if ($adapter) {
        $stats = Get-Counter "\Network Interface($($adapter.InterfaceDescription))\Bytes Total/sec" -SampleInterval 1 -MaxSamples 1
        $speed = [math]::Round($stats.CounterSamples[0].CookedValue / 1MB, 2)
        Write-Host "   Interface: $($adapter.Name)" -ForegroundColor White
        Write-Host "   Speed: $($adapter.LinkSpeed)" -ForegroundColor White
        Write-Host "   Current: $speed MB/s" -ForegroundColor White
    }
    Write-Host ""
}

function Get-GPUStats {
    Write-Host "🎮 GPU PERFORMANCE:" -ForegroundColor Green
    try {
        # NVIDIA GPU stats
        $nvidiaOutput = nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>$null
        if ($nvidiaOutput) {
            $gpuData = $nvidiaOutput.Split(',')
            Write-Host "   NVIDIA: $($gpuData[0].Trim())" -ForegroundColor White
            Write-Host "   Usage: $($gpuData[1].Trim())%" -ForegroundColor White
            Write-Host "   Memory: $($gpuData[2].Trim())MB / $($gpuData[3].Trim())MB" -ForegroundColor White
            Write-Host "   Temp: $($gpuData[4].Trim())°C" -ForegroundColor White
        }
    } catch {
        Write-Host "   NVIDIA GPU: Not available or nvidia-smi not found" -ForegroundColor Yellow
    }
    
    try {
        # Intel GPU stats (basic)
        $intelGPU = Get-Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction SilentlyContinue
        if ($intelGPU) {
            $maxUtil = ($intelGPU.CounterSamples | Measure-Object CookedValue -Maximum).Maximum
            Write-Host "   Intel GPU Usage: $([math]::Round($maxUtil, 1))%" -ForegroundColor White
        }
    } catch {
        Write-Host "   Intel GPU: Stats not available" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Get-StreamingStats {
    Write-Host "📺 STREAMING STATS:" -ForegroundColor Green
    try {
        # SRT Stats
        $srtStats = Invoke-RestMethod -Uri "http://192.168.50.194:8277/stats" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($srtStats) {
            Write-Host "   SRT Server: Active" -ForegroundColor Green
            # Parse and display stats if available
        } else {
            Write-Host "   SRT Server: No response" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   SRT Server: Not accessible" -ForegroundColor Red
    }
    
    try {
        # RTMP Stats
        $rtmpStats = Invoke-RestMethod -Uri "http://192.168.50.194:8080/stat" -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($rtmpStats) {
            Write-Host "   RTMP Server: Active" -ForegroundColor Green
        } else {
            Write-Host "   RTMP Server: No response" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   RTMP Server: Not accessible" -ForegroundColor Red
    }
    Write-Host ""
}

function Get-SystemHealth {
    Write-Host "💻 SYSTEM HEALTH:" -ForegroundColor Green
    
    # CPU Usage
    $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1
    Write-Host "   CPU Usage: $([math]::Round($cpu.CounterSamples[0].CookedValue, 1))%" -ForegroundColor White
    
    # Memory Usage
    $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $availableMemory = (Get-Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue / 1024
    $usedMemory = $totalMemory - $availableMemory
    $memoryPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 1)
    Write-Host "   Memory: $([math]::Round($usedMemory, 1))GB / $([math]::Round($totalMemory, 1))GB ($memoryPercent%)" -ForegroundColor White
    
    # Disk I/O
    $disk = Get-Counter "\PhysicalDisk(_Total)\Disk Bytes/sec" -SampleInterval 1 -MaxSamples 1
    $diskMBps = [math]::Round($disk.CounterSamples[0].CookedValue / 1MB, 2)
    Write-Host "   Disk I/O: $diskMBps MB/s" -ForegroundColor White
    
    Write-Host ""
}

# Main monitoring loop
Write-Host "Starting real-time monitoring... Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

while ($true) {
    Clear-Host
    Write-Host "🖥️ STREAMING SERVER PERFORMANCE MONITOR - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Get-SystemHealth
    Get-DockerStats
    Get-NetworkStats
    Get-GPUStats
    Get-StreamingStats
    
    Write-Host "⏱️ Refreshing in 5 seconds... (Ctrl+C to stop)" -ForegroundColor Gray
    Start-Sleep -Seconds 5
}