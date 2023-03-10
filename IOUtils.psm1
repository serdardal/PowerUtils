function Get-KeyValues {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path
	)
	
	$pairs = @()
	
	$content = @(Get-Content -Path $Path -Encoding 'UTF8')
	
	for($i = 0; $i -lt $content.Count; $i++){
		$line = $content[$i]
		$line = $line.Trim()
		
		if($line -eq ''){
			continue
		}
		
		$seperatorIndex = $line.IndexOf('=');
		
		if($seperatorIndex -eq -1){
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
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path,
		
		[Parameter(Mandatory=$true)]
		[string]$Key,
		
		[Parameter(Mandatory=$true)]
		[string]$Value
	)
	
	if(-Not (Test-Path -Path $Path)){
		Set-Content -Path $Path -Value $null -Encoding 'UTF8'
	}
	
	$lines = @(Get-Content -Path $Path -Encoding 'UTF8')
	
	$settingLineIdx = $null
	for($i = 0; $i -lt $lines.Count; $i++){
		$line = $lines[$i]
		if($line.StartsWith("$($Key)=")){
			$settingLineIdx = $i
			break
		}
	}
	
	if($settingLineIdx -eq $null){
		$lines += "$($Key)=$($Value)"
	}
	else{
		$lines[$settingLineIdx] = "$($Key)=$($Value)"
	}
	
	Set-Content -Path $Path -Value $lines -Encoding 'UTF8'
}

function Import-ModuleFromGallery {
	param(
		[Parameter(Mandatory=$true)]
		[string]$ModuleName,
		
		[bool]$AllowClobber = $false
	)
	
	if(Get-Module -ListAvailable -Name $ModuleName) {
		Import-Module $ModuleName
	}
	else{

		# If module is not imported, not available on disk, but is in online gallery then install and import
		if(Find-Module -Name $ModuleName | Where-Object {$_.Name -eq $ModuleName}) {
			Install-Module -Name $ModuleName -Force -Verbose -Scope AllUsers -AllowClobber:$AllowClobber
			Import-Module $ModuleName
		}
		else{

			# If module is not imported, not available and not in online gallery then abort
			throw "Module $ModuleName not imported, not available and not in online gallery, exiting."
		}
	}
}