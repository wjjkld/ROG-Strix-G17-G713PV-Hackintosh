/*
 * SSDT-CHGLIMIT: ASUS battery charge limit for macOS (ROG Strix G17 G713PV, BIOS G713PV.334)
 *
 * Windows (Armoury Crate / MyASUS) sets the limit by calling the ASUS WMI method
 *   \_SB.ATKD.WMNB(0, "DEVS", { DeviceID = 0x00120057 (battery RSOC), Value = percent })
 * This DSDT then (lines ~10858-10872 of the 2026-11-08 dump):
 *   - sets SBRG.BH30 = 0x50 when the limit is <= 80 (else 0) and notifies BAT0
 *   - calls ATKD.SRSC(percent) -> SBRG.SECC(0x0C, percent): EC command 0x0C via I/O ports 0x68/0x6C
 * The EC wait loops (WIBF) time out after 0x10000 polls, so this cannot hang boot.
 *
 * This SSDT makes the same call once at boot, only when running macOS.
 * Change CHLM to another value (e.g. 60, 100) and recompile to change the limit; 100 = no limit.
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "CHGLIMIT", 0x00000000)
{
    External (_SB_.ATKD, DeviceObj)
    External (_SB_.ATKD.WMNB, MethodObj)    // 3 Arguments

    Scope (\_SB)
    {
        Device (CHGL)
        {
            Name (_HID, "CHGL0000")  // _HID: Hardware ID
            Name (CHLM, 80)          // charge limit in percent

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0B)    // present, enabled, not shown in UI
                }

                Return (Zero)
            }

            Method (SETL, 1, Serialized)
            {
                If (CondRefOf (\_SB.ATKD.WMNB))
                {
                    // WMNB reads five DWORDs from Arg2, so pass 20 bytes
                    Local0 = Buffer (0x14) {}
                    CreateDWordField (Local0, Zero, DVID)
                    CreateDWordField (Local0, 0x04, DVAL)
                    DVID = 0x00120057
                    DVAL = Arg0
                    \_SB.ATKD.WMNB (Zero, 0x53564544, Local0)  // 0x53564544 = "DEVS"
                }
            }

            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                If (_OSI ("Darwin"))
                {
                    SETL (CHLM)
                }
            }
        }
    }
}
