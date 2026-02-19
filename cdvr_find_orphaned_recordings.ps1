<#
.SYNOPSIS
    Finds orphaned recordings in a Channels DVR installation.

.DESCRIPTION
    Connects to a Channels DVR instance, retrieves the list of recording paths from the DVR database, 
    checks the storage paths for video files, and identifies any "orphaned" recordings — video files 
    that exist on disk but are not listed in the DVR database. 
    The script then prints a list of these orphaned recordings.

.AUTHOR
    Gildas Lefur (a.k.a. "mjitkop" in the Channels DVR forums)

.NOTES
    This is an unofficial script and is NOT supported by the developers of Channels DVR.

.VERSION
    1.0.0 – Initial public release.
#>

#===============================================================================
#                          INPUT PARAMETERS (OPTIONAL)
#===============================================================================

param(
    [string]$Ip = "127.0.0.1",
    [string]$Port = "8089"
)

#===============================================================================
#                                   FUNCTIONS
#===============================================================================

function Get-StoragePaths {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DvrUrl
    )

    Write-Host "`nFetching storage paths from the server..."

    $paths = @()

    try {
        # GET /dvr
        $response = Invoke-RestMethod -Uri "$DvrUrl/dvr" -Method GET

        # Extract "path" and "extra_paths"
        if ($response.path) {
            $paths += $response.path
        }

        if ($response.extra_paths) {
            $paths += $response.extra_paths
        }
    }
    catch {
        Write-Host "Error fetching recording paths: $($_.Exception.Message)"
        exit 1
    }

    Write-Host " -> Retrieved storage paths: $($paths -join ', ')"
    return $paths
}

function Get-RecordingPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DvrUrl
    )

    Write-Host "`nFetching recording paths from the server..."

    $paths = @()

    try {
        # GET /api/v1/all
        $response = Invoke-RestMethod -Uri "$DvrUrl/api/v1/all" -Method GET

        foreach ($recording in $response) {
            if ($recording.path) {
                $paths += $recording.path
            }
        }
    }
    catch {
        Write-Host "Error fetching recording paths: $($_.Exception.Message)"
        exit 1
    }

    Write-Host " -> Retrieved $($paths.Count) recording paths from the server."
    return $paths
}

function Get-FilesOnDisks {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    Write-Host "`nChecking storage paths for files..."
    $files = @()

    foreach ($path in $Paths) {
        foreach ($directory in Get-ChildItem -Path $path -Directory) {
            if ($directory.Name -in @("Movies", "TV")) {
                $dvrDirectory = Join-Path $path $directory.Name
                # Get all items inside Movies/ or TV/
                $recordings = Get-ChildItem -Path $dvrDirectory
                Write-Host " -> Found $($recordings.Count) files in $dvrDirectory"

                foreach ($recording in $recordings) {
                    $filePath = Join-Path $dvrDirectory $recording.Name
                    if (Test-Path $filePath -PathType Leaf) {
                        $files += $filePath
                    }
                }
            }
        }
    }

    Write-Host "-> Found a total of $($files.Count) files on disks."
    return $files
}

function Is-VideoFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Filename
    )

    $videoExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".ts", ".mpeg", ".mpg")
    $extension = [System.IO.Path]::GetExtension($Filename).ToLower()

    return $videoExtensions -contains $extension
}

#===============================================================================
#                                 MAIN PROGRAM
#===============================================================================

function Main {
    param(
        [string]$Ip = "127.0.0.1",
        [string]$Port = "8089"
    )

    # Build base URL
    $dvrUrl = "http://$Ip`:$Port"
    Write-Host "Using Channels DVR at: $dvrUrl"

    # Fetch recording paths from API
    $recordingPaths = Get-RecordingPaths -DvrUrl $dvrUrl

    # Fetch storage paths from /dvr
    $storagePaths = Get-StoragePaths -DvrUrl $dvrUrl

    # Enumerate all files on disk
    $filesOnDisks = Get-FilesOnDisks -Paths $storagePaths

    # Detect orphaned recordings
    $orphanedRecordings = @()

    foreach ($file in $filesOnDisks) {
        if ((Is-VideoFile -Filename $file) -and ($recordingPaths -notcontains $file)) {
            $orphanedRecordings += $file
        }
    }

    # Output results
    if ($orphanedRecordings.Count -gt 0) {
        Write-Host "`nFound $($orphanedRecordings.Count) orphaned recordings:"
        foreach ($recording in $orphanedRecordings) {
            Write-Host " -> $recording"
        }
    }
    else {
        Write-Host "`nNo orphaned recordings found."
    }
}

Main -Ip $Ip -Port $Port
