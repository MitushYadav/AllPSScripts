<#script to take ownership of a folder and grant Full control to a principal
    consists of 2 steps:
    1. take ownership of the folder and set child objects to inherit
    2. allow "Everyone" security object Full Control over child objects + replace child properties with inheritable props
#>



[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateScript({Test-Path $_ })]
  [string]
  $ItemPath,
  [Parameter(Mandatory=$false)]
  [string]
  $NewOwner = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
)

#region
#P/Invoke'd C# code to enable required privileges to take ownership and make changes when NTFS permissions are lacking
$AdjustTokenPrivileges = @"
using System;
using System.Runtime.InteropServices;

 public class TokenManipulator
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
  ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll", ExactSpelling = true)]
  internal static extern IntPtr GetCurrentProcess();
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
  phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name,
  ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool AddPrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
  public static bool RemovePrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_DISABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
 }
"@
add-type $AdjustTokenPrivileges
[void][TokenManipulator]::AddPrivilege("SeRestorePrivilege") #Necessary to set Owner Permissions
[void][TokenManipulator]::AddPrivilege("SeBackupPrivilege") #Necessary to bypass Traverse Checking
[void][TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege") #Necessary to override FilePermissions
#endregion


# take ownership
$subItems = Get-ChildItem -Path $ItemPath -Recurse

$NewAccount = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $NewOwner

foreach($item in $subItems) {
  $acl = $null
  $acl = Get-Acl -Path $item.FullName
  $acl.SetOwner($NewAccount)
  Set-Acl -Path $item.FullName -AclObject $acl
}

#group to give full rights to
$fullRightsGroup = "BUILTIN\Everyone"

#give full control to everyone
$newAcl = Get-Acl -Path $ItemPath
$fileSystemRights = [System.Security.AccessControl.FileSystemRights]::FullControl
$inheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit
$propagationFlag = [System.Security.AccessControl.PropagationFlags]::None
$accessControlType = [System.Security.AccessControl.AccessControlType]::Allow
$fsRights = New-Object System.Security.AccessControl.FileSystemAccessRule($fullRightsGroup, $fileSystemRights, $inheritanceFlag, $propagationFlag, $accessControlType)
$newAcl.SetAccessRule($fsRights)
Set-Acl -Path $ItemPath -AclObject $newAcl