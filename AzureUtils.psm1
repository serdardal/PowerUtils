function Get-KeyVaultSecretValue {
	param (
		[Parameter(Mandatory=$true)]
		[string]$VaultName,

		[Parameter(Mandatory=$true)]
		[string]$Name
	)

	try {
		$value = Get-AzKeyVaultSecret -VaultName $VaultName -Name $Name -AsPlainText -ErrorAction Stop
		return $value.Trim()
	}
	catch [System.Management.Automation.PSInvalidOperationException] {
		if($_.Exception.Message -eq 'Run Connect-AzAccount to login.'){
			Connect-AzAccount | Out-Null

			$value = Get-AzKeyVaultSecret -VaultName $VaultName -Name $Name -AsPlainText -ErrorAction Stop
			return $value.Trim()						
		}
		else{
			# rethrowing exception
			throw $_.Exception
		}
	}
	catch {
		# rethrowing exception
		throw $_.Exception
	}

}