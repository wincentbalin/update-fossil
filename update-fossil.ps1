# Update Fossil SCM binary

# Get version of the local Fossil SCM
$localFossilVersionOutput = fossil version

if ($localFossilVersionOutput -notmatch ".*version ([\d\.]+) \[.*")
{
    Write-Output "Could not find Fossil version number in the following output:"
    Write-Output $localFossilVersionOutput
    exit 1
}

$localFossilVersion = [double]$Matches[1]

Write-Output "Local Fossil SCM version: $localFossilVersion"

# Get version and URI of the remote Fossil SCM
$remoteFossilVersion = 0.0
$remoteFossilFileName = ""
$binaries = Invoke-WebRequest -Uri http://fossil-scm.org/index.html/juvlist | ConvertFrom-Json
foreach ($bo in $binaries)
{
    if ($bo.name -match "fossil-w32-([\d\.]+).zip")
    {
        $binaryVersion = [double]$Matches[1]
        if ($binaryVersion -gt $remoteFossilVersion)
        {
            $remoteFossilVersion = $binaryVersion
            $remoteFossilFileName = $bo.name
        }
    }
}

if ($remoteFossilVersion -eq 0)
{
    Write-Output "Could not glean remote Fossil SCM version from:"
    Write-Output $binaries
    exit 1
}

Write-Output "Remote Fossil SCM version: $remoteFossilVersion"

# Update Fossil SCM, if needed
if ($remoteFossilVersion -gt $localFossilVersion)
{
    Write-Output "Updating..."
    # Download zip file
    $remoteZipFileUri = "http://fossil-scm.org/index.html/uv/$remoteFossilFileName"
    $tmpZipFile = "$env:TEMP\fossil.zip"
    Invoke-WebRequest -Uri $remoteZipFileUri -OutFile $tmpZipFile
    # Expand zip file to a temporary directory
    $tmpDirectory = "$env:TEMP\update-fossil"
    New-Item -Type Directory -Path $tmpDirectory | Out-Null
    Expand-Archive -LiteralPath $tmpZipFile -DestinationPath $tmpDirectory
    # Replace Fossil binary
    $localFossilDirectory = (Get-Command fossil).Path | Split-Path -Parent
    Move-Item -Path "$tmpDirectory\fossil.exe" -Destination $localFossilDirectory -Force
    # Clean up
    Remove-Item $tmpDirectory -Recurse -Force
    Remove-Item $tmpZipFile -Force
    Write-Output "Done"
}
else
{
    Write-Output "No update needed"
}
