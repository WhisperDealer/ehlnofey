<#
.SYNOPSIS
  Quick check of the census JSON (census/**/*.json) that needs nothing but Windows PowerShell 5.1.

.DESCRIPTION
  The census site validates every file against the full Zod schema when it builds
  (`npm run schema` or `npm run build` in site/). This script repeats the checks that matter most
  for hand edits without Node:

    - the file parses as JSON, with no UTF-8 BOM
    - a family's `id` matches its filename and its `group` matches its folder
    - every family a group.json lists exists, and every family file is listed by its group
    - a sub-group's `parent` names a group that exists
    - every `formKey` is `<6 upper-case hex>:<Master.esm|esp|esl>` (never bare hex)
    - every record row has a `level.kind` the site knows and a `target.band` of I-X with a
      `target.status` of proposed or implemented, or a `target.scales` (an exception to bone 1)

.EXAMPLE
  powershell -File build/Test-CensusJson.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Census = Join-Path $RepoRoot 'census'
$script:Errors = @()

function Add-Error([string]$File, [string]$Message) {
    $rel = $File.Substring($RepoRoot.Length).TrimStart('\', '/')
    $script:Errors += "$rel : $Message"
}

function Read-Json([string]$File) {
    $bytes = [System.IO.File]::ReadAllBytes($File)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Add-Error $File 'has a UTF-8 BOM; write it with UTF8Encoding($false)'
    }
    try { return ([System.Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF) | ConvertFrom-Json) }
    catch { Add-Error $File "is not valid JSON: $($_.Exception.Message)"; return $null }
}

function Has([object]$Obj, [string]$Name) {
    return ($null -ne $Obj) -and ($Obj.PSObject.Properties.Name -contains $Name)
}

# Every formKey anywhere in the document.
function Test-FormKeys([object]$Node, [string]$File) {
    if ($null -eq $Node) { return }
    if ($Node -is [System.Array]) { foreach ($n in $Node) { Test-FormKeys $n $File }; return }
    if ($Node -isnot [System.Management.Automation.PSCustomObject]) { return }
    foreach ($p in $Node.PSObject.Properties) {
        if ($p.Name -eq 'formKey' -and $p.Value -notmatch '^[0-9A-F]{6}:[A-Za-z0-9 _.''-]+\.(esm|esp|esl)$') {
            Add-Error $File "bad formKey '$($p.Value)' (want <6 upper-case hex>:<Master.esm>)"
        }
        Test-FormKeys $p.Value $File
    }
}

$BandIds = 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'
$Kinds = 'fixed', 'pcMult', 'template', 'list'

$bandsFile = Join-Path $Census 'bands.json'
$bandsDoc = Read-Json $bandsFile
if ($null -ne $bandsDoc -and @($bandsDoc.bands).Count -ne 10) { Add-Error $bandsFile 'must hold exactly ten bands' }

foreach ($dir in Get-ChildItem -LiteralPath $Census -Directory | Where-Object { $_.Name -ne 'schema' }) {
    $groupFile = Join-Path $dir.FullName 'group.json'
    $listed = @()
    if (-not (Test-Path -LiteralPath $groupFile)) { Add-Error $dir.FullName 'has no group.json' }
    else {
        $group = Read-Json $groupFile
        if ($null -ne $group) {
            if ($group.id -ne $dir.Name) { Add-Error $groupFile "id '$($group.id)' should be '$($dir.Name)'" }
            if ((Has $group 'parent') -and -not (Test-Path -LiteralPath (Join-Path (Join-Path $Census $group.parent) 'group.json'))) {
                Add-Error $groupFile "names parent '$($group.parent)', which has no census/$($group.parent)/group.json"
            }
            $listed = @($group.families | ForEach-Object { $_.id })
            foreach ($id in $listed) {
                if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName "$id.json"))) { Add-Error $groupFile "lists '$id', which has no $id.json" }
            }
            Test-FormKeys $group $groupFile
        }
    }

    foreach ($file in Get-ChildItem -LiteralPath $dir.FullName -Filter '*.json' | Where-Object { $_.Name -ne 'group.json' }) {
        $f = Read-Json $file.FullName
        if ($null -eq $f) { continue }
        if ($f.id -ne $file.BaseName) { Add-Error $file.FullName "id '$($f.id)' should be '$($file.BaseName)'" }
        if ($f.group -ne $dir.Name) { Add-Error $file.FullName "group '$($f.group)' should be '$($dir.Name)'" }
        if ($listed -notcontains $f.id) { Add-Error $file.FullName "is not listed in $($dir.Name)/group.json" }
        foreach ($row in @($f.records.rows)) {
            $where = "record row '$($row.id)'"
            if (-not (Has $row 'level') -or $Kinds -notcontains $row.level.kind) { Add-Error $file.FullName "$where has no known level.kind ($($Kinds -join ', '))" }
            if (-not (Has $row 'target')) { Add-Error $file.FullName "$where has no target" }
            elseif (Has $row.target 'scales') {
                # An exception to bone 1: keeps scaling with the player.
                if ($row.target.scales -ne $true -or 'proposed', 'implemented' -notcontains $row.target.status) { Add-Error $file.FullName "$where target.scales must be true, proposed or implemented" }
            }
            elseif ($BandIds -notcontains $row.target.band) { Add-Error $file.FullName "$where has no target.band of I-X" }
            elseif ('proposed', 'implemented' -notcontains $row.target.status) { Add-Error $file.FullName "$where target.status must be proposed or implemented" }
        }
        Test-FormKeys $f $file.FullName
    }
}

if ($script:Errors.Count -gt 0) {
    $script:Errors | ForEach-Object { Write-Host "ERROR  $_" -ForegroundColor Red }
    Write-Host "$($script:Errors.Count) problem(s). For the full schema check run 'npm run schema' in site/."
    exit 1
}
Write-Host 'census JSON ok' -ForegroundColor Green
