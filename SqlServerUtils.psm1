class ConnectionObject {
	[string] $ServerName
	[string] $DatabaseName
	[string] $Username
	[string] $Password
	[string] $ConnectionString

	ConnectionObject(
		[string] $ServerName,
		[string] $DatabaseName,
		[string] $Username,
		[string] $Password
	){
		$this.ServerName = $ServerName
		$this.DatabaseName = $DatabaseName
		$this.Username = $Username
		$this.Password = $Password
		$this.ConnectionString = GetConnectionString $this
	}
}

function GetConnectionString([ConnectionObject]$connObj){
	$trustedConnection = 'false'
	if (($connObj.Username -eq '') -or ($connObj.Password -eq '')){
		$trustedConnection = 'true'
	}

	return "Server=$($connObj.ServerName);Database=$($connObj.DatabaseName);trusted_connection=$trustedConnection;User Id=$($connObj.Username);Password=$($connObj.Password);"
}

function Create-ConnectionObject {
	param(
		[Parameter(Mandatory=$true)]
		[string]$ServerName,

		[Parameter(Mandatory=$true)]
		[string]$DatabaseName,

		[string]$Username,

		[string]$Password
	)

	return [ConnectionObject]::new($ServerName, $DatabaseName, $Username, $Password)
}