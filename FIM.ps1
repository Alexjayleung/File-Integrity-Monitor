Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline??"
Write-Host ""

$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""

Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists(){
    $baselineExists = Test-Path -Path .\baseline.txt
    
    if ($baselineExists) {
        # Delete it
        Remove-Item -Path .\baseline.txt
    }
}
 

if ($response -eq "A".ToUpper()) {
    # Delete baseline.txt if it already exists
    Erase-Baseline-If-Already-Exists
    
    # Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files
    
    # For file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}

elseif ($response -eq "B".ToUpper()){
   
    $fileHashDictionary = @{}
    # Load file|hash from baseline.txt and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathsAndHashes) {
        $fileHashDictionary.add($f.split("|")[0], $f.split("|")[1])
    }

    #Begin (continuously) monitoring files with saved Baseline
    while ($true) {
        Start-Sleep -seconds 1

        $files = Get-ChildItem -Path .\Files
    
        # For file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName
            

            if ($fileHashDictionary[$hash.Path] -eq $null) {
                # A new file has been created!
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            else {
                # Notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # File has not changed
                }
                else {
                    # File has been compromised!, notify the user
                    Write-Host "$($hash.Path) has changed!" -ForegroundColor Red
                }

            }
            foreach ($key in $fileHashDictionary.keys) {
                $baselineFileStillExists = Test-Path -Path $key
                if (-Not $baselineFileStillExists) {
                   # One of the baseline files must have been deleted, notify the user
                   Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed
                }

            }

        }

    }
    

    # Begin monitoring files with saved Baseline
    Write-Host "Read existing baseline.txt, start monitoring files" -Foregroundcolor Yellow
}
