$fontUrls = @{
    "Poppins-Regular.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf"
    "Poppins-Medium.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf"
    "Poppins-SemiBold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf"
    "Poppins-Bold.ttf" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
}

$fontDir = "assets/fonts"

foreach ($font in $fontUrls.GetEnumerator()) {
    $outputPath = Join-Path $fontDir $font.Key
    Write-Host "Downloading $($font.Key)..."
    Invoke-WebRequest -Uri $font.Value -OutFile $outputPath
}

Write-Host "Font download complete!" 