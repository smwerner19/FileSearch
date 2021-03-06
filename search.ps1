<#
.SYNOPSIS
    Use PowerShell to search for files.
.DESCRIPTION
    Simple script to use PowerShell to search for a specific file.
.NOTES
    Author:  Stefan M. Werner
    Website: http://getninjad.com
#>

Param (
	[Parameter(Position=0, Mandatory=$false, HelpMessage="Path to target file for processing. Defaults to computers.txt.")] [string]$File = 'computers.txt',
	[Parameter(Position=0, Mandatory=$false, HelpMessage="Computer name for processing. Cannot be combined with file switch.")] [string]$ComputerName,
    [Parameter(Position=1, Mandatory=$true, HelpMessage="The name of the file to search for.")] [string]$FileName,
	[Parameter(Position=2, Mandatory=$true, HelpMessage="The extension of the file to search for.")] [string]$FileExt
)

# Get current directory
$scriptpath = $MyInvocation.MyCommand.Path
$currentdir = Split-Path $scriptpath

# Get computer name(s) for processing
If ($ComputerName)
{
	$computers = $ComputerName
}
Else
{
	$computers = Get-Content $currentdir\$File
}

$d = Get-Date
$d = $d.ToString("yyyyMMdd-HHmm")

$Logfile = $currentdir + '\result' + $d + '.txt'

foreach ($computer in $computers) {
	If (Test-Connection -ComputerName $computer -Quiet -Count 1)
	{
		Write-Host "Searching $computer..."
		
		# Search using cmdlet (slow!)
		#$result = Get-ChildItem \\$computer\c$\ -recurse -Filter "$FileName.$FileExt" -ErrorAction SilentlyContinue
		
		# Search using Windows Management Instrumentation class (faster)
		# - filename: Just the files name without an extension.
		# - name: Is the full file path.
		# - drive: Specify a drive to search. Dropping this will search all available drives, excluding network shares.
		# - extension: The files extension.
		$result = Get-WmiObject -Query "SELECT name, filesize FROM CIM_DataFile WHERE filename = '$FileName' AND extension = '$FileExt'" -ComputerName $computer
		
		Add-content $Logfile -value $computer
		Add-content $Logfile -value '------------------------------'
		# If using cmdlet: .FullName    	If using WMI: .Name
		Add-content $Logfile -value $result.Name 
		Add-content $Logfile -value '------------------------------'
	}
	Else
	{
		Write-Host "$computer appears to be offline."
	}
}