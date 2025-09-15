Param(
    [string]$SourceDir = "..\images",
    [string]$TargetDir = "..\images_resized",
    [int]$MaxWidth = 520
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $SourceDir)) {
    Write-Error "SourceDir introuvable: $SourceDir"
    exit 1
}

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

Get-ChildItem -LiteralPath $SourceDir -Include *.png,*.jpg,*.jpeg,*.gif -File | ForEach-Object {
    $src = $_.FullName
    $dst = Join-Path -Path (Resolve-Path $TargetDir) -ChildPath $_.Name

    try {
        $img = [System.Drawing.Image]::FromFile($src)
        $origW = $img.Width
        $origH = $img.Height

        if ($origW -le $MaxWidth) {
            Copy-Item -LiteralPath $src -Destination $dst -Force
            $img.Dispose()
            Write-Output "Copi� (d�j� petit): $($_.Name)"
            return
        }

        $ratio = $MaxWidth / [double]$origW
        $newW = [int]$MaxWidth
        $newH = [int][math]::Round($origH * $ratio)

        $bmp = New-Object System.Drawing.Bitmap $newW, $newH
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.DrawImage($img, 0, 0, $newW, $newH)

        if ($_.Extension -match '(?i)png') {
            $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
        } elseif ($_.Extension -match '(?i)jpe?g') {
            $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        } else {
            $bmp.Save($dst)
        }

        $g.Dispose()
        $bmp.Dispose()
        $img.Dispose()
        Write-Output "Redimensionn�: $($_.Name) -> ${newW}x${newH}"
    } catch {
        Write-Warning "�chec redimensionnement: $($_.Exception.Message) pour $src"
    }
}
