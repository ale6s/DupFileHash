param(
    [string]$FilePath,           # Path of the file to check
    [string]$OutPutHashFile,     # Path to the hash file
    [int]$MaxHistory             # How many hashes to add to the file, also means for how many hashes/files will go back to look for
)

function GetFileHashContent {
    param (
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        # Calculate SHA256 hash of the file
        return Get-FileHash -Path $FilePath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    } else {
        throw "File not Found: $FilePath"   
    }
}

# Validate Parameters
if (-not (Test-Path $FilePath)) {
    throw "File to check not found at: $FilePath. Provide a valid path/file."
}
if (-not (Test-Path $OutPutHashFile)) {
    Write-Host "Hash file not found. Creating a new one at: $OutPutHashFile."
    New-Item -ItemType File -Path $OutPutHashFile -Force | Out-Null
}

# Read existing hashes and dates
$existingLines = Get-Content $OutPutHashFile
$previousHashes = @()
foreach ($line in $existingLines) {
    if ($line -notmatch '^#') { # Skip lines starting with '#'
        $previousHashes += $line
    }
}

# Calculate the hash of the current file
$currentHash = GetFileHashContent -FilePath $FilePath

# Check for duplicate
if ($previousHashes -contains $currentHash) {
    throw "Duplicate file detected. Script failed." 
}

# Proceed only if no duplicate is detected
Write-Host "No duplicate detected. Proceeding with upload..."

# Prepare the new hash entry with date
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$newHashEntry = @("# Date: $date - $FilePath", $currentHash)

# Update the hash file with the current hash and date
$updatedHashes = $existingLines + $newHashEntry

# Limit the number of stored hashes (and their dates) to MaxHistory
if ($updatedHashes.Count -gt ($MaxHistory * 2)) { # Each hash has a date line, so multiply MaxHistory by 2
    $updatedHashes = $updatedHashes[-($MaxHistory * 2)..-1]
}

# Save the updated hashes back to the file
$updatedHashes | Out-File -FilePath $OutPutHashFile -Encoding UTF8 -Force

Write-Host "Hashes updated successfully."



#to call this use 
#powershell -File "Z:\path\path\main.ps1" -FilePath "Z:\path\path\test.txt" -OutPutHashFile "Z:\path\path\HashFile.txt" -MaxHistory 7
