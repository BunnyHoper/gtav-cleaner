# --- FORZAR CODIFICACIÓN UTF-8 EN LA CONSOLA ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- DECLARAR MÉTODOS NATIVOS DE WINDOWS ---
$ntdllCode = @"
using System;
using System.Runtime.InteropServices;

public class ProcessControl {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtSuspendProcess(IntPtr processHandle);

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtResumeProcess(IntPtr processHandle);
}
"@
Add-Type -TypeDefinition $ntdllCode -ErrorAction SilentlyContinue

# --- BUSCAR EL PROCESO ---
$processName = "GTA5_Enhanced"
$process = Get-Process -Name $processName -ErrorAction SilentlyContinue

if (-not $process) {
    Write-Host "GTA5 no encontrado." -ForegroundColor Red
    exit
}

# --- CONGELAR EL JUEGO ---
[ProcessControl]::NtSuspendProcess($process.Handle)

# --- PORCENTAJE ANIMADO ---
$total = 10
for ($i = $total; $i -ge 0; $i--) {
    Clear-Host
    
    # Calcular porcentaje
    $pct = ($total - $i) / $total
    $percent = [int]($pct * 100)

    # Definir color según avance
    if ($pct -lt 0.34) { $color = "Red" }
    elseif ($pct -lt 0.67) { $color = "Yellow" }
    else { $color = "Green" }

    Write-Host ""
    Write-Host "   ESTADO: EN PROGRESO" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   $percent %" -ForegroundColor $color
    Write-Host ""
    Write-Host "   Tiempo restante: $i s" -ForegroundColor White
    Write-Host ""

    Start-Sleep -Seconds 1
}

# --- REANUDAR EL JUEGO ---
[ProcessControl]::NtResumeProcess($process.Handle)
Clear-Host
Write-Host ""
Write-Host "   ESTADO: COMPLETADO" -ForegroundColor Green
Write-Host ""
Write-Host "   100 %" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 1

# --- SELECCIONAR VENTANA DE GTA V ---
$wshell = New-Object -ComObject WScript.Shell
$wshell.AppActivate($process.Id) | Out-Null
Start-Sleep -Milliseconds 300 

Write-Host "   Secuencia terminada con éxito!" -ForegroundColor Cyan
Start-Sleep -Seconds 1
exit
