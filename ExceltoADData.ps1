#Declare the file path and sheet name
$file = "C:\Temp\ime.xlsx"
$sheetName = "Sheet1"
#Create an instance of Excel.Application and Open Excel file
$objExcel = New-Object -ComObject Excel.Application
$workbook = $objExcel.Workbooks.Open($file)
$sheet = $workbook.Worksheets.Item($sheetName)
$objExcel.Visible=$false
#Count max row
$rowMax = ($sheet.UsedRange.Rows).count
#Declare the starting positions
$row,$col = 1,1

#loop to get value and run a Get-ADUser against it
for($i=1; $i -le $rowMax-1; $i++)
{
$email = $sheet.Cells.Item($i,1).text
Get-ADUser -filter {EmailAddress -match $email} -credential prod\myadav
}
