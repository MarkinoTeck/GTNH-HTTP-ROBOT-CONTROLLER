# GTNH-HTTP-ROBOT-CONTROLLER

## Content

- [Information](#information)
- [Installation](#installation)

<a id="information"></a>

## Information

Program is designed to use opencomputer robots using http requests.
And there is also the possibility of auto update at startup.

<a id="installation"></a>

## Installation

> [!CAUTION]
> If you are using 8 java, the installer will not work for you.
> The only way to install the program is to manually transfer it to your computer.
> The problem is on the java side.

To install program, you need a t2 computer with:
- Graphics Card (Tier 1+): 1
- Central Processing Unit (CPU) (Tier 1+): 1
- Memory (Tier 3.5): 1
- Hard Disk Drive (Tier 3) (4MB): 1
- EEPROM (Lua BIOS): 1
- Internet Card: 1

Install the basic Open OS on your computer.
Then run the command to start the installer.

```shell
wget -f https://raw.githubusercontent.com/MarkinoTeck/GTNH-OC-Installer/main/installer.lua && installer
```

Then select the Water Line Control program in the installer.
If you wish you can add the program to auto download, for manual start write a command.

Then move the EEPROM and the Hard Disk Drive

```shell
main
```
