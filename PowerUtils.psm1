function Get-KeyValues {
	param(
		[Parameter(Mandatory=$true)]
		[string]$Path
	)
	
	$pairs = @()
	
	$content = @(Get-Content -Path $Path -Encoding 'UTF8')
	
	for($i = 0; $i -lt $content.Count; $i++){
		$line = $content[$i]
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