#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
    $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }

# Export the Public modules
Export-ModuleMember -Function $Public.Basename -Alias *

# Check for existance of options file and copy default if none
if (-not (Test-Path $Home\rubrik_sdk_for_powershell_options.json)) {
    Write-Host "Options file doesn't exist, creating default"
    Copy-Item -Path $PSScriptRoot\OptionsDefault\rubrik_sdk_for_powershell_options.json -Destination $Home\
}

$rubrikOptions = Get-Content -Raw -Path $Home\rubrik_sdk_for_powershell_options.json | ConvertFrom-JSON
# Add any newly created options into user defined options file
$rubrikDefaults = Get-Content -Raw -Path $PSScriptRoot\OptionsDefault\rubrik_sdk_for_powershell_options.json | ConvertFrom-Json

$rubrikDefaults.DefaultParameterValues.PSObject.Properties | ForEach-Object {
    Write-Host "Checking user file for $($_.Name)"
    if ($rubrikOptions.DefaultParameterValues.PSObject.Properties["$($_.name)"]) {
        Write-Host "$($_.Name) exists already"
    }
    else {
        Write-Host "$($_.Name) not found in user file, will add default value of $($_.Value)"
        Add-Member -InputObject $rubrikOptions.DefaultParameterValues -NotePropertyName "$($_.Name)" -NotePropertyValue "$($_.Value)"
    }
}

$rubrikDefaults.ModuleOptions.PSObject.Properties | ForEach-Object {
    Write-Host "Checking user file for $($_.Name)"
    if ($rubrikOptions.ModuleOptions.PSObject.Properties["$($_.name)"]) {
        Write-Host "$($_.Name) exists already"
    }
    else {
        Write-Host "$($_.Name) not found in user file, will add default value of $($_.Value)"
        Add-Member -InputObject $rubrikOptions.ModuleOptions -NotePropertyName "$($_.Name)" -NotePropertyValue "$($_.Value)"
    }
}

# Export $rubrikOptions back to user file...
Write-Host "writing back to file"
$rubrikOptions | ConvertTO-Json | Out-File $Home\rubrik_sdk_for_powershell_options.json

# Load defaults into global variable
$global:rubrikOptions = $rubrikOptions

# Load Default Parameter Values
$Global:rubrikOptions.DefaultParameterValues.PSObject.Properties | ForEach-Object {
    Write-Host "Processing $($_.Name)"
    if ($_.Value -ne "") {
        Write-Host "Will setup $($_.Name) as it isn't null"
        $Global:PSDefaultParameterValues = @{"*:$($_.Name)" = "$($_.Value)"}
        Write-Host $PSDefaultParameterValues
    }
    else {
        Write-Host "Skipping $($_.Name) as it is null"
    }
}

