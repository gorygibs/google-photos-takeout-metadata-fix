# Invoke-GPhotosMetadataFix.ps1
param (
    [string]$PhotoRoot = "D:\Downloads\Takeout\Google Photos\Photos from 2023\New folder",
    [string]$ExifToolPath = "D:\Applications\exiftool\exiftool.exe"
)

$extensions = "*.jpg","*.jpeg","*.png","*.mp4","*.mov"

Write-Host "Starting metadata restore in $PhotoRoot ..."
Get-ChildItem -Path $PhotoRoot -Include $extensions -Recurse -File | ForEach-Object {

    $img = $_
    $dir = $img.Directory.FullName
    $imgName = [string]$img.Name
    $baseName = [string]$img.BaseName
    $imgPath = $img.FullName
    $ext = $img.Extension.ToLower()
    $jsonPath = $null
    $usedFallback = $false

    # 🔹 Cleaned base name (remove common suffixes like (1), -edited, -cropped, etc.)
    $cleanBase = $baseName -replace '(\(.*\))','' `
                            -replace '(-edited|_edited|-cropped|_cropped|-edit|_edit|-mod|_mod)$','' `
                            -replace '\s+$',''

    # 1️⃣ Explicit candidate list (JSON detection logic unchanged)
    $explicit = @(
        "$imgName.supplemental-metadata.json",
        "$baseName.supplemental-metadata.json",
        "$cleanBase.supplemental-metadata.json",
        "$imgName.supplemental-me.json",
        "$baseName.supplemental-me.json",
        "$cleanBase.supplemental-me.json",
        "$imgName.supplementa.json",
        "$baseName.supplementa.json",
        "$cleanBase.supplementa.json",
        "$baseName.json",
        "$cleanBase.json"
    )
    foreach ($e in $explicit) {
        $cand = Join-Path -Path $dir -ChildPath $e
        if (Test-Path $cand) { $jsonPath = $cand; break }
    }

    # 2️⃣ Wildcard matches (JSON detection logic unchanged)
    if (-not $jsonPath) {
        $possible = Get-ChildItem -Path $dir -Filter "$cleanBase*.json" -ErrorAction SilentlyContinue
        if ($possible) { $jsonPath = $possible[0].FullName }
    }

    # 3️⃣ Substring matches (JSON detection logic unchanged)
    if (-not $jsonPath) {
        $allJsons = Get-ChildItem -Path $dir -Filter *.json -ErrorAction SilentlyContinue
        if ($allJsons) {
            $match = $allJsons | Where-Object {
                ($_.Name -imatch [regex]::Escape($baseName)) -or
                ($_.Name -imatch [regex]::Escape($cleanBase))
            } | Select-Object -First 1
            if ($match) { $jsonPath = $match.FullName }
        }
    }

    if (-not $jsonPath) {
        Write-Warning "JSON not found for $imgName"
        return
    }

    Write-Host "Using JSON for $imgName -> $(Split-Path $jsonPath -Leaf)"
    $json = $null
    try { $json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json }
    catch { Write-Warning "Could not parse JSON for $imgName"; return }

    # 🕒 DATE resolution - CLEANED SPACING & REGEX
    $dateStr = $null
    if ($json.photoTakenTime -and $json.photoTakenTime.formatted) { $dateStr = $json.photoTakenTime.formatted }
    elseif ($json.creationTime -and $json.creationTime.formatted) { $dateStr = $json.creationTime.formatted }
    # Fix for IMG_YYYYMMDD_HHMMSS pattern
    elseif ($cleanBase -match '(\d{8})_(\d{6})') { 
        $dateDigits = $matches[1]; $timeDigits = $matches[2]
        $year = $dateDigits.Substring(0,4)
        $month = $dateDigits.Substring(4,2)
        $day = $dateDigits.Substring(6,2)
        $hour = $timeDigits.Substring(0,2)
        $min = $timeDigits.Substring(2,2)
        $sec = $timeDigits.Substring(4,2)
        # Previously fixed to use unambiguous format
        $dateStr = "$year-$month-$day $hour`:$min`:$sec" 
    }

    $exifDate = $null
    if ($dateStr) {
        $dateStr = $dateStr -replace 'Sept','Sep' -replace ' UTC$','' 
        try {
            $dt = [datetime]::Parse($dateStr, [System.Globalization.CultureInfo]::InvariantCulture)
            $exifDate = $dt.ToString("yyyy:MM:dd HH:mm:ss")
        } catch {
            Write-Warning ("Failed to parse date for {0} ({1})" -f $imgName, $dateStr)
        }
    }

    # 📝 Description (unchanged)
    $desc = $null
    if ($json.description -and $json.description.Trim().Length -gt 0) { $desc = $json.description.Trim() }

    # 📍 GeoData (unchanged)
    $lat = $json.geoData.latitude
    $lon = $json.geoData.longitude
    $alt = if ($json.geoData.altitude) { $json.geoData.altitude } else { 0 }
    $hasGeo = ($lat -ne 0 -or $lon -ne 0)

    # 🧩 Check existing metadata (unchanged)
    $skip = $false
    if ($exifDate) {
        $existingDate = ""
        if ($ext -in @(".jpg",".jpeg",".png")) {
            $existingDate = & $ExifToolPath -EXIF:DateTimeOriginal -s3 $imgPath
        } elseif ($ext -in @(".mp4",".mov")) {
            $existingDate = & $ExifToolPath -QuickTime:CreateDate -s3 $imgPath
        }
        if ($existingDate -eq $exifDate) {
            Write-Host "Skipping $imgName — already has correct Date Taken / Media Created"
            $skip = $true
        }
    }

    if ($skip) { return }

    # Build ExifTool args (unchanged)
    $args = @("-P","-overwrite_original")
    if ($exifDate) {
        if ($ext -in @(".jpg",".jpeg",".png")) {
            $args += "-EXIF:DateTimeOriginal=$exifDate"
            $args += "-EXIF:CreateDate=$exifDate"
            $args += "-EXIF:ModifyDate=$exifDate"
            $args += "-XMP:CreateDate=$exifDate"
            $args += "-XMP:DateCreated=$exifDate"
        } elseif ($ext -in @(".mp4",".mov")) {
            $args += "-QuickTime:CreateDate=$exifDate"
            $args += "-QuickTime:ModifyDate=$exifDate"
            $args += "-TrackCreateDate=$exifDate"
            $args += "-TrackModifyDate=$exifDate"
            $args += "-MediaCreateDate=$exifDate"
            $args += "-MediaModifyDate=$exifDate"
        }
    }
    if ($desc) {
        if ($ext -in @(".mp4",".mov")) {
            $args += "-XMP:Description=$desc"
            $args += "-QuickTime:Comment=$desc"
        } else {
            $args += "-ImageDescription=$desc"
            $args += "-XMP:Description=$desc"
        }
    }
    if ($hasGeo) {
        $args += "-EXIF:GPSLatitude=$lat"
        $args += "-EXIF:GPSLongitude=$lon"
        if ($alt -ne 0) { $args += "-EXIF:GPSAltitude=$alt" }
    }

    $args += $imgPath
    & $ExifToolPath @args | Out-Null
    Write-Host "Updated metadata for $imgName"
}

Write-Host "`n============================================="
Write-Host " Metadata restoration complete."
Write-Host "============================================="
