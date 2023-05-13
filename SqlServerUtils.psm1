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

function GetConnectionString([ConnectionObject]$connObj) {
	$trustedConnection = 'false'
	if (($connObj.Username -eq '') -or ($connObj.Password -eq '')){
		$trustedConnection = 'true'
	}

	return "Server=$($connObj.ServerName);Database=$($connObj.DatabaseName);trusted_connection=$trustedConnection;User Id=$($connObj.Username);Password=$($connObj.Password);"
}

function Create-ConnectionObject {
	param (
		[Parameter(Mandatory=$true)]
		[string]$ServerName,

		[Parameter(Mandatory=$true)]
		[string]$DatabaseName,

		[string]$Username,

		[string]$Password
	)

	return [ConnectionObject]::new($ServerName, $DatabaseName, $Username, $Password)
}

function Invoke-SqlFile {
	param (
		[Parameter(Mandatory=$true)]
		[ConnectionObject]$ConnectionObject,

		[Parameter(Mandatory=$true)]
		[string]$SqlFilePath,

		[bool]$UseDatabase = $true,

		[switch]$RunVerbose
	)

	if (-Not (Test-Path -Path $SqlFilePath)) {
		throw "Sql file not found: $SqlFilePath"
	}

	$params = @{
		InputFile = $SqlFilePath
		ServerInstance = $ConnectionObject.ServerName
		Verbose = $RunVerbose
		QueryTimeout = 0 # unlimited
	}

	if ($UseDatabase) {
		$params['Database'] = $ConnectionObject.DatabaseName
	}

	if (($ConnectionObject.Username -ne '') -And ($ConnectionObject.Password -ne '')) {
		$params['Username'] = $ConnectionObject.Username
		$params['Password'] = $ConnectionObject.Password
	}

	Invoke-Sqlcmd @params
}

function Invoke-SqlCommand {
	param (
		[Parameter(Mandatory=$true)]
		[ConnectionObject]$ConnectionObject,

		[Parameter(Mandatory=$true)]
		[string]$Command,

		[bool]$UseDatabase = $true,

		[switch]$RunVerbose
	)

	$params = @{
		Query = $Command
		ServerInstance = $ConnectionObject.ServerName
		Verbose = $RunVerbose
		QueryTimeout = 0 # unlimited
	}

	if ($UseDatabase) {
		$params['Database'] = $ConnectionObject.DatabaseName
	}

	if (($ConnectionObject.Username -ne '') -And ($ConnectionObject.Password -ne '')) {
		$params['Username'] = $ConnectionObject.Username
		$params['Password'] = $ConnectionObject.Password
	}

	Invoke-Sqlcmd @params
}

function Get-QueryResultTables {
	param (
		[Parameter(Mandatory=$true)]
		[ConnectionObject]$ConnectionObject,

		[Parameter(Mandatory=$true)]
		[string]$Query
	)

	$connection = New-Object System.Data.SqlClient.SQLConnection
	$connection.ConnectionString = $ConnectionObject.ConnectionString

	$command = New-Object System.Data.SQLClient.SQLCommand
	$command.Connection = $connection
	$command.CommandText = $Query
	$command.CommandTimeout = 0 # unlimited

	try {
		$connection.Open()

		$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
		$dataset = New-Object System.Data.DataSet
		$adapter.Fill($dataSet) | Out-Null

		return ,$dataset.Tables
	}
	catch {
		throw 'Error occured while getting query result!'
	}
	finally {
		$connection.Close()
		$connection.Dispose()
	}
}