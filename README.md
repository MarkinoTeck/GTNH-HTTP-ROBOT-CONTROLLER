# GTNH-HTTP-Robot-Controller

## Content

- [Information](#information)
- [Installation](#installation)
- [Robot Assembly](#robot-examples)
- [Credits](#credits)


<a id="information"></a>

## Information

Program is designed to control opencomputer robots using http requests.
And there is also the possibility of auto update at startup.


<a id="installation"></a>

## Installation

> [!CAUTION]
> If you are using 8 java, the installer will not work for you.
> The only way to install the program is to manually transfer it to your computer.
> The problem is on the java side.

### Downloading softwere using installer:

- Install the basic Open OS on your robot.
- Then run the command to start the installer.
```shell
wget -f https://raw.githubusercontent.com/MarkinoTeck/GTNH-OC-Installer/main/installer.lua && installer
```
- Select the "Robot" program in the installer.
- Enable auto restart typing "y" when prompted.

## Robot Assembly:

Inside robot:

- 1x "Screen (Tier 1)"
- 1x "Keyboard"
- 1x "Disk Drive"
- 1x "ME Upgrade" (tier 3)
- 1x "Database Upgrade (Tier 1)"
- 1x "Angel Upgrade"
- 1x "Hover Upgrade (Tier 2)"
- 1x "Chunkloader Upgrade"
- 1x "Memory (Tier 3.5)"
- 1x "Central Processing Unit (CPU) (Tier 3)"
- 1x "Internet Card"
- 1x "EEPROM (Lua BIOS)"
- 1x "Hard Disk Drive (Tier 3) (4MB)"
- 1x "Computer Case (Tier 3)"
- 1x "Navigation Upgrade"
- 1x "Inventory Controller Upgrade"
- 2x "Upgrade Container (Tier 1)"

In Upgrade Containers:

- 1x "Inventory Upgrade" (Upgrade Container)
- 1x Geolyzer (Upgrade Container)

![Computer Example](/docs/robot_preset.png)


<a id="credits"></a>

## Credits:
~~~
Install Script: based on Navatusein's code
~~~