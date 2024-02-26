<#
.SYNOPSIS
    Add the corresponding function names to Bochs call logs.
.DESCRIPTION
    Bochs can generate call logs with the debugger command `show call`, for example:
    ```console
    00016253385: call 0008:c0003dba (0xc0003dba) (phy: 0x000000003dba) unk. ctxt
    00016253389: call 0008:c0001566 (0xc0001566) (phy: 0x000000001566) unk. ctxt
    00016253399: call 0008:c0003dec (0xc0003dec) (phy: 0x000000003dec) unk. ctxt
    ```
    This script can add the corresponding function name for each call with the Linux `nm` command and a provided module. The formatted log will be:
    ```console
    00016253385: call 0008:c0003dba (0xc0003dba) (phy: 0x000000003dba) unk. ctxt [_function1]
    00016253389: call 0008:c0001566 (0xc0001566) (phy: 0x000000001566) unk. ctxt [_function2]
    00016253399: call 0008:c0003dec (0xc0003dec) (phy: 0x000000003dec) unk. ctxt [_function3]
    ```
.PARAMETER ModulePath
    The path of a compiled module.
.PARAMETER LogPath
    The path of a Bochs call log file.
    If it is not set, the script will read logs from the clipboard.
.OUTPUTS
    Formatted call logs.
.EXAMPLE
    PS> .\Format-CallLog.ps1 -ModulePath 'kernel.bin' -LogPath 'call.log'
    The script reads and formats call logs from the file `call.log` using the module `kernel.bin`.
.EXAMPLE
    PS> .\Format-CallLog.ps1 -ModulePath 'kernel.bin'
    The script reads and formats call logs from the clipboard using the module `kernel.bin`.
.NOTES
    The script is based on Linux Bochs v2.7. The call log format may be changed in higher versions.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ModulePath,

    [ValidateNotNullOrEmpty()]
    [string]$LogPath
)

<#
.SYNOPSIS
    Extract function names and addresses from a module using the Linux `nm` command and save them into a hash table.
#>
function Import-Module {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $file = New-TemporaryFile
    Start-Process -FilePath 'nm' -ArgumentList $Path -NoNewWindow -Wait -RedirectStandardOutput $file

    $mod = @{}
    New-Variable -Name 'name_idx' -Value 2 -Option Constant
    New-Variable -Name 'addr_idx' -Value 0 -Option Constant
    foreach ($line in Get-Content -Path $file) {
        $fields = $line.Split()
        $name = $fields[$name_idx]
        $addr = $fields[$addr_idx]
        if (!$mod.ContainsKey($addr)) {
            $mod.Add($addr, $name)
        } else {
            Write-Verbose "Name conflict at 0x$addr`: $name <=> $($mod[$addr])"
        }
    }

    return $mod
}

<#
.SYNOPSIS
    Add the corresponding function name for each Bochs call log with a provided name-address hash table.
.INPUTS
    Bochs call logs.
.OUTPUTS
    Formatted call logs.
#>
function Format-CallLog {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Module,

        [Parameter(ValueFromPipeline)]
        [string]$CallLog
    )

    process {
        if (![string]::IsNullOrWhiteSpace($CallLog)) {
            $CallLog = $CallLog.Trim()
            $rgx = [regex]'(?<=\(0x)\w{8}'
            $match = $rgx.Match($CallLog)
            if ($match.Success) {
                $addr = $match.Value
                if ($Module.ContainsKey($addr)) {
                    Write-Output "$CallLog [$($Module[$addr])]"
                } else {
                    Write-Verbose "Failed to find a name at 0x$addr"
                    Write-Output $CallLog
                }
            } else {
                Write-Verbose "Failed to match an address in '$CallLog'"
            }
        }
    }
}

try {
    $mod = Import-Module -Path $ModulePath
    $log = $LogPath ? (Get-Content -Path $LogPath) : (Get-Clipboard)
    $log | Format-CallLog -Module $mod
} catch {
    Write-Host $_ -ForegroundColor Red
}