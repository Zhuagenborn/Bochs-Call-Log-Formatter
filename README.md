# *Bochs* Call Log Formatter

![PowerShell](badges/PowerShell.svg)
![Linux](badges/Linux.svg)
![License](badges/License-MIT.svg)

## Introduction

![Cover](Cover.png)

This script can add the corresponding function names to [***Bochs***](https://bochs.sourceforge.io) call logs with the *Linux* `nm` command and a provided executable module.

## Usage

Suppose we have an executable module called `kernel.bin` which is running in *Bochs*.

After enabling call logging with the `show call` command, *Bochs* can generate call logs such as:

```console
00016253385: call 0008:c0003dba (0xc0003dba) (phy: 0x000000003dba) unk. ctxt
00016253389: call 0008:c0001566 (0xc0001566) (phy: 0x000000001566) unk. ctxt
00016253399: call 0008:c0003dec (0xc0003dec) (phy: 0x000000003dec) unk. ctxt
```

It is inconvenient for users because *Bochs* does not display function names.

To match each function address and its name, we can copy call logs to a file `call.log` and run:

```console
PS> .\Format-CallLog.ps1 -ModulePath 'kernel.bin' -LogPath 'call.log'
```

The formatted logs will be written to the pipeline.

```console
00016253385: call 0008:c0003dba (0xc0003dba) (phy: 0x000000003dba) unk. ctxt [_function1]
00016253389: call 0008:c0001566 (0xc0001566) (phy: 0x000000001566) unk. ctxt [_function2]
00016253399: call 0008:c0003dec (0xc0003dec) (phy: 0x000000003dec) unk. ctxt [_function3]
```

## License

Distributed under the *MIT License*. See `LICENSE` for more information.