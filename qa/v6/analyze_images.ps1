param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Paths)
Add-Type -AssemblyName System.Drawing

foreach ($path in $Paths) {
    if (-not (Test-Path $path)) { Write-Output "{`"file`":`"$path`",`"error`":`"missing`"}"; continue }
    $bmp = [System.Drawing.Bitmap]::new($path)
    $w = $bmp.Width; $h = $bmp.Height
    $step = [Math]::Max(4, [int]($w / 160))
    $total = 0; $lit16 = 0; $lit40 = 0; $lit80 = 0; $colorful = 0; $sumLum = 0.0
    $cx0 = [int]($w * 0.25); $cx1 = [int]($w * 0.75)
    $cy0 = [int]($h * 0.25); $cy1 = [int]($h * 0.75)
    $ctotal = 0; $clit16 = 0; $clit40 = 0; $clit80 = 0; $csumLum = 0.0
    for ($y = 0; $y -lt $h; $y += $step) {
        for ($x = 0; $x -lt $w; $x += $step) {
            $p = $bmp.GetPixel($x, $y)
            $lum = 0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B
            $total++; $sumLum += $lum
            if ($lum -gt 16) { $lit16++ }
            if ($lum -gt 40) { $lit40++ }
            if ($lum -gt 80) { $lit80++ }
            if (([Math]::Abs($p.R - $p.G) + [Math]::Abs($p.G - $p.B) + [Math]::Abs($p.B - $p.R)) -gt 60) { $colorful++ }
            if ($x -ge $cx0 -and $x -lt $cx1 -and $y -ge $cy0 -and $y -lt $cy1) {
                $ctotal++; $csumLum += $lum
                if ($lum -gt 16) { $clit16++ }
                if ($lum -gt 40) { $clit40++ }
                if ($lum -gt 80) { $clit80++ }
            }
        }
    }
    $bmp.Dispose()
    $avg = if ($total -gt 0) { [Math]::Round($sumLum / $total, 2) } else { 0 }
    $cavg = if ($ctotal -gt 0) { [Math]::Round($csumLum / $ctotal, 2) } else { 0 }
    $pct = { param($n) if ($total -gt 0) { [Math]::Round(100.0 * $n / $total, 2) } else { 0 } }
    $cpct = { param($n) if ($ctotal -gt 0) { [Math]::Round(100.0 * $n / $ctotal, 2) } else { 0 } }
    Write-Output ("{`"file`":`"$path`",`"bytes`":$((Get-Item $path).Length),`"size`":`"${w}x${h}`",`"avgLum`":$avg,`"lit16`":$(& $pct $lit16),`"lit40`":$(& $pct $lit40),`"lit80`":$(& $pct $lit80),`"colorful`":$(& $pct $colorful),`"centerAvgLum`":$cavg,`"centerLit16`":$(& $cpct $clit16),`"centerLit40`":$(& $cpct $clit40),`"centerLit80`":$(& $cpct $clit80)}")
}
