function Get-KeyValues {
	param (
		[Parameter(Mandatory=$true)]
		[string]$Path
	)
	
	$pairs = @()
	
	$content = @(Get-Content -Path $Path -Encoding 'UTF8')
	
	for ($i = 0; $i -lt $content.Count; $i++) {
		$line = $content[$i]
		$line = $line.Trim()
		
		if ($line -eq '') {
			continue
		}
		
		$seperatorIndex = $line.IndexOf('=');
		
		if ($seperatorIndex -eq -1) {
			$errLine = $i + 1
			Throw "Key-Value seperator (=) not found! Line: $errLine"
		}
		
		$pairs += [PSCustomObject]@{
			Key = $line.SubString(0, $seperatorIndex)
			Value = $line.SubString($seperatorIndex + 1, $line.Length - $seperatorIndex - 1)
		}
	}
	
	return ,$pairs
}

function Set-KeyValue {
	param (
		[Parameter(Mandatory=$true)]
		[string]$Path,
		
		[Parameter(Mandatory=$true)]
		[string]$Key,
		
		[Parameter(Mandatory=$true)]
		[string]$Value
	)
	
	if (-Not (Test-Path -Path $Path)) {
		Set-Content -Path $Path -Value $null -Encoding 'UTF8'
	}
	
	$lines = @(Get-Content -Path $Path -Encoding 'UTF8')
	
	$settingLineIdx = $null
	for ($i = 0; $i -lt $lines.Count; $i++) {
		$line = $lines[$i]
		if ($line.StartsWith("$($Key)=")) {
			$settingLineIdx = $i
			break
		}
	}
	
	if ($settingLineIdx -eq $null) {
		$lines += "$($Key)=$($Value)"
	}
	else {
		$lines[$settingLineIdx] = "$($Key)=$($Value)"
	}
	
	Set-Content -Path $Path -Value $lines -Encoding 'UTF8'
}

function Import-ModuleFromGallery {
	param (
		[Parameter(Mandatory=$true)]
		[string]$ModuleName,
		
		[switch]$AllowClobber,
		
		[string]$Version
	)
	
	if (Get-Module -ListAvailable -Name $ModuleName) {
		Import-Module $ModuleName -Global
	}
	else {

		# if module is not imported, not available on disk, but is in online gallery then install and import
		if (Find-Module -Name $ModuleName | Where-Object { $_.Name -eq $ModuleName }) {
			$installParams = @{
				Name = $ModuleName
				Force = $true
				Verbose = $true
				Scope = 'AllUsers'
				AllowClobber = $AllowClobber
			}
			
			if ($Version -ne '') {
				$installParams['RequiredVersion'] = $Version
			}
			
			Install-Module @installParams
			
			Import-Module $ModuleName -Global
		}
		else {

			# if module is not imported, not available and not in online gallery then abort
			throw "Module $ModuleName not imported, not available and not in online gallery, exiting."
		}
	}
}

function Import-ModuleFromLocalRarFile {
	param (
		[Parameter(Mandatory=$true)]
		[string]$RarExePath,

		[Parameter(Mandatory=$true)]
		[string]$ModuleName,

		[Parameter(Mandatory=$true)]
		[string]$ModuleRarPath,

		[Parameter(Mandatory=$true)]
		[string]$ExtractionPath
	)

	try {
		if (-Not (Test-Path -Path $ExtractionPath)) {
			New-Item -Path $ExtractionPath -ItemType 'directory' | Out-Null
		}

		$moduleFolderPath = "$ExtractionPath\$ModuleName"

		if (-Not (Test-Path -Path $moduleFolderPath)) {
			$information = & cmd /c "`"$RarExePath`" x `"$ModuleRarPath`" *.* `"$ExtractionPath`" 2>&1" | Out-String

			if ($LASTEXITCODE -ne 0) {
			  throw $information
			}
		}

		Import-Module -Name $moduleFolderPath -Global -ErrorAction Stop 2>$null

		if (-Not (Get-Module -Name $ModuleName)) {
			throw "$ModuleName module not imported!."
		}
	}
	catch{
		Write-Host 'Error occured while extracting modules!' -ForegroundColor 'Red'

		# rethrowing exception
		throw $_.Exception
	}
}