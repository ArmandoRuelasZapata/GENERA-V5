
$assetsPath = "c:\Users\Alan\Desktop\RESIDENCIA_THE_ORIGINAL_LAB\theoriginallab_v2\assets"
$libPath = "c:\Users\Alan\Desktop\RESIDENCIA_THE_ORIGINAL_LAB\theoriginallab_v2\lib"
$unusedPath = "$assetsPath\unused_legacy"

# Create unused directory if it doesn't exist
if (!(Test-Path -Path $unusedPath)) {
    New-Item -ItemType Directory -Path $unusedPath | Out-Null
}

# Subdirectories to exclude (don't move files FROM here, but we can check files IN here)
# Actually, the user wants to clean up everything.
# Let's list all files in assets recursively, excluding the unused_legacy folder itself.
$files = Get-ChildItem -Path $assetsPath -Recurse -File | Where-Object { $_.DirectoryName -notlike "*unused_legacy*" }

foreach ($file in $files) {
    $fileName = $file.Name
    
    # Correct recursive search: searching IN files inside Lib
    $hit = Get-ChildItem -Path $libPath -Filter "*.dart" -Recurse | Select-String -Pattern $fileName -SimpleMatch -List

    if (!$hit) {
        # Double check pubspec.yaml for root assets like splash screens or icons
        $hitPubspec = Select-String -Path "c:\Users\Alan\Desktop\RESIDENCIA_THE_ORIGINAL_LAB\theoriginallab_v2\pubspec.yaml" -Pattern $fileName -SimpleMatch -List
        
        if (!$hitPubspec) {
            Write-Host "Moving unused asset: $fileName"
            
            $dest = "$unusedPath\$fileName"
            if (Test-Path $dest) {
                Write-Host "File exists in destination, skipping: $fileName"
            }
            else {
                # Ensure destination directory exists (if flattening)
                Move-Item -Path $file.FullName -Destination $unusedPath
            }
        }
    }
}
