Function Get-SystemChassisType {
	$sysChaTypeNumber = [string](Get-WMIObject -Query "SELECT ChassisTypes FROM Win32_SystemEnclosure").ChassisTypes
	If ( $sysChaTypeNumber -in '3', '4', '6', '7', '16', '24' ) { $sysChaType = 'Desktop' }
	If ( $sysChaTypeNumber -in '8', '9', '10', '11', '14' ) { $sysChaType = 'Portable' }
	If ( $sysChaTypeNumber -in '5', '23' ) { $sysChaType = 'Rackmount' }
	return $sysChaType
}