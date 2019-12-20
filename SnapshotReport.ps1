#Version 2.0

function Get-SnapshotReport{
	$SnapReport  = @()
	
    function Replace-SpecialChars {
    param(
        [string]$InputString,
        [string]$Replacement  = "",
        [string]$SpecialChars = "[]"
    )
    $rePattern = ($SpecialChars.ToCharArray() |ForEach-Object { [regex]::Escape($_) }) -join "|"
    $InputString -replace $rePattern,$Replacement
	}
			

	$VC = $vCenter.Name+ "@443"	
	$DC = (Get-datacenter).name
	$VMids = get-view -viewtype VirtualMachine | where{$_.snapshot -ne $null}
	if($VMids)
	{
	$date = Get-Date -Format 'yyyyMMdd_HHmm'
	foreach ($VMid in $VMids){
		$snap = $VMid.snapshot.RootSnapshotList
		$snapevent = Get-VIEvent -Entity $VMid.Name -Types Info -Finish $snap.CreateTime -MaxSamples 1 | Where-Object 
{$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
		$SnapTotal = "" | select vCenter, OS, VM, Name, Description, Created, CreatedBy, SizeGB
	if ($snapevent -ne $null)
	{
		$SnapTotal.VM = $VMid.Name
		$SnapTotal.vCenter = $vCenter.name
		$SnapTotal.Name = $snap.Name
		$SnapDate = [datetime]$snap.CreateTime
		$SnapTotal.Created = $SnapDate.tostring('yyyy.MM.dd hhtt')
		$SnapTotal.Description = $snap.Description
		if($VMid.layoutEx.file| where {($_.name -like "*sesparse*")})
		{
		$F_Size = 0
		$names = $VMid.LayoutEx.file.name  | where {($_ -like "*delta*") -or ($_ -like "*sesparse*")}
		foreach($name in $names)
		{
			$new_name = Replace-SpecialChars $name
			$new_name2 = $new_name -replace '\s', '\'
			$new_name3 = $new_name2 -replace '/', '\'
			$Size = (ls vmstores:\$VC\$DC\$new_name3).Length
			$F_Size += $Size
		}
		$SnapTotal.SizeGB = ($F_size/1GB).tostring("f2")
		}
		Else
		{$SnapTotal.SizeGB = ((($VMid.layoutEx.file | where {($_.name -like "*delta*") -or ($_.name -like "*sesparse*")}).Size | 

Measure-Object -sum).Sum/1024/1024/1024).tostring("f2")}
		$SnapTotal.CreatedBy = $snapevent.UserName
		if($VMid.guest.GuestFamily -like "*win*")
		{$SnapTotal.OS = 'Windows'}Else
		{$SnapTotal.OS = 'Linux'}
		$SnapReport += $SnapTotal
	}
	Else{
		$SnapTotal.VM = $VMid.Name
		$SnapTotal.vCenter = $vCenter.name
		$SnapTotal.Name = $snap.Name
		$SnapDate = [datetime]$snap.CreateTime
		$SnapTotal.Created = $SnapDate.tostring('yyyy.MM.dd hhtt')
		$SnapTotal.Description = $snap.Description
		if($VMid.layoutEx.file| where {($_.name -like "*sesparse*")})
		{
		$F_Size = 0
		$names = $VMid.LayoutEx.file.name  | where {($_ -like "*delta*") -or ($_ -like "*sesparse*")}
		foreach($name in $names)
		{
			$new_name = Replace-SpecialChars $name
			$new_name2 = $new_name -replace '\s', '\'
			$new_name3 = $new_name2 -replace '/', '\'
			$Size = (ls vmstores:\$VC\$DC\$new_name3).Length
			$F_Size += $Size
		}
		$SnapTotal.SizeGB = ($F_size/1GB).tostring("f2")
		}
		Else
		{$SnapTotal.SizeGB = ((($VMid.layoutEx.file | where {($_.name -like "*delta*") -or ($_.name -like "*sesparse*")}).Size | Measure-Object -sum).Sum/1024/1024/1024).tostring("f2")}
		$SnapTotal.CreatedBy = 'NA'
		if($VMid.guest.GuestFamily -like "*win*")
		{$SnapTotal.OS = 'Windows'}
		Else
		{$SnapTotal.OS = 'Linux'}
		$SnapReport += $SnapTotal
		}
		}
		}
		
#$VMs = Get-VM  | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded}
$VMs= Get-View -ViewType VirtualMachine  | Where-Object {$_.Runtime.ConsolidationNeeded}
If($VMs)
{
	foreach($VM in $VMs)
	{
		$VMTotal = "" | select vCenter, OS, VM, Name, Description, Created, CreatedBy, SizeGB
		$VMTotal.vCenter = $vCenter.Name
		if($VM.guest.GuestFamily -like "*win*")
		{$SnapTotal.OS = 'Windows'}Else
		{$SnapTotal.OS = 'Linux'}
		$VMTotal.VM = $VM.Name
		$VMTotal.Name = "Critical!"
		$VMTotal.Description = "Failed Snapshot Cleanup, Require to re-consolicate!"
		$VMTotal.Created = "NA"
		$VMTotal.CreatedBy = "NA"
		$VMTotal.SizeGB = ((($VM.layoutEx.file | where {($_.Type -like "diskExtent") -and ($_.name -like "*delta*")}).Size | Measure-Object -sum).Sum/1024/1024/1024).tostring("f2")
		$SnapReport += $VMTotal
	}
}
return $SnapReport
}
