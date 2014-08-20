DEFCON22RTU
===========

DEF CON 22 badge RTU firmware.  Implements a Modbus slave on the badge.

- Registers 40001 - 40003 turn on LEDs 1,2,3 when their value >= 1.
- Registers 30001 - 30004 are incrementing counters related to the E, F, C and O touchpads.  These correspond to LEDs 4, 5, 6 and 7.
- LED 8 is an activity light related to processing serial input.
- Modbus serial implemented via the USB interface for ease of use.
- Supports Modbus function codes 03, 04 and 06.


Acknowledgements
================

- Modbus RTU spin code is thanks to Paul Clyne (pacman on the Forums).
- Based on code originally supplied by Olivier Jauzelon.
- Kurenko - for his help with word/long/byte confusion.
- Jon "JonnyMac" McPhalen and Ryan "1o57" Clarke for the DC22 badge design and source.

Original source code before fork is located here: http://obex.parallax.com/object/687
