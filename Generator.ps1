param (
    [string]$db
)

# Get the directory where the script is located
$scriptDir = $PSScriptRoot

# Load and parse the dependencies JSON file
$dependenciesPath = Join-Path $scriptDir "dependencies.json"
$dependencies = Get-Content $dependenciesPath | ConvertFrom-Json

# Define the output file path
$outputFile = Join-Path $scriptDir ".out.sql"

# Clear the output file if it already exists
if (Test-Path $outputFile) {
    Clear-Content $outputFile
}

# Add database creation and usage statement if -db parameter is provided
if (-not [string]::IsNullOrEmpty($db)) {
    $dbCreationStatement = @"
CREATE DATABASE IF NOT EXISTS ``$db``;
USE ``$db``;
"@
    Add-Content -Path $outputFile -Value $dbCreationStatement
}

$setUtcTimezoneStatement = @"
SET time_zone = '+00:00';
"@
Add-Content -Path $outputFile -Value $setUtcTimezoneStatement

# --- Topological Sort ---

$inDegree = @{}
$graph = @{}
$nodes = @()

# Process tables, functions, and procedures
$allItems = @{}
$dependencies.psobject.properties | ForEach-Object {
    $itemType = $_.Name
    $items = $_.Value

    $items.psobject.properties | ForEach-Object {
        $itemName = $_.Name
        $nodes += $itemName
        $graph[$itemName] = @()
        $inDegree[$itemName] = 0
        $allItems[$itemName] = $itemType
    }
}

$dependencies.psobject.properties | ForEach-Object {
    $itemType = $_.Name
    $items = $_.Value

    $items.psobject.properties | ForEach-Object {
        $itemName = $_.Name
        $itemDeps = $_.Value

        # Assuming dependencies are listed under a property like 'tables' or similar
        $itemDeps.psobject.properties | ForEach-Object {
            if ($_.Name -in @('tables', 'functions', 'procedures')) {
                $dependencyList = $_.Value
                foreach ($dep in $dependencyList) {
                    if ($nodes -contains $dep) {
                        $graph[$dep] += $itemName
                        $inDegree[$itemName]++
                    }
                }
            }
        }
    }
}


$queue = [System.Collections.Queue]::new()
foreach ($node in $nodes) {
    if ($inDegree[$node] -eq 0) {
        $queue.Enqueue($node)
    }
}

$sortedList = @()
while ($queue.Count -gt 0) {
    $node = $queue.Dequeue()
    $sortedList += $node

    if ($graph.ContainsKey($node)) {
        foreach ($neighbor in $graph[$node]) {
            $inDegree[$neighbor]--
            if ($inDegree[$neighbor] -eq 0) {
                $queue.Enqueue($neighbor)
            }
        }
    }
}

if ($sortedList.Count -ne $nodes.Count) {
    Write-Error "Error: A circular dependency was detected."
    exit 1
}

# --- File Merging ---

# Define the order of SQL files to be merged for each table
$fileOrder = @(
    "table.sql",
    "columns.sql",
    "constraints.sql",
    "foreignkeys.sql",
    "indices.sql",
    "data.sql"
)

Start-Sleep -Seconds 1

foreach ($itemName in $sortedList) {
    $itemType = $allItems[$itemName]
    
    Add-Content -Path $outputFile -Value "-- Merging files for ${itemType}: ${itemName}"

    if ($itemType -eq 'tables') {
        $itemPath = Join-Path -Path $scriptDir -ChildPath "$itemType\$itemName"
        if (Test-Path -LiteralPath $itemPath) {
            foreach ($file in $fileOrder) {
                $sqlFilePath = Join-Path $itemPath $file
                if (Test-Path -LiteralPath $sqlFilePath) {
                    Write-Host "Merging: $sqlFilePath"
                    $content = Get-Content $sqlFilePath -Raw
                    Add-Content -Path $outputFile -Value $content
                    Add-Content -Path $outputFile -Value "" # Add a newline for separation
                }
            }
        }
    }
    elseif ($itemType -in @('procedures', 'functions')) {
        $sqlFilePath = Join-Path $scriptDir "$itemType\$itemName.sql"
        if (Test-Path -LiteralPath $sqlFilePath) {
            Write-Host "Merging: $sqlFilePath"
            $content = Get-Content $sqlFilePath -Raw
            Add-Content -Path $outputFile -Value $content
            Add-Content -Path $outputFile -Value "" # Add a newline for separation
        }
    }
}

Write-Host "Successfully created merged SQL file at: $outputFile"
