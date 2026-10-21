/*
 * billie battery: TI bq27541 fuel gauge on QUP0 SE2 (i2c@888000, 0x55), read by bq27541.
 * Claims no resources: a52q's DSDT (currently shipped as billie's DSDT) may declare the same
 * QUP block, so the driver maps SE2 itself.
 */
DefinitionBlock ("SSDT_Battery.aml", "SSDT", 2, "QCOMM ", "BILLIEBT", 1)
{
    Scope (\_SB)
    {
        Device (BAT0)
        {
            Name (_HID, "WOAT0003")
            Name (_UID, 0)

            Method (_STA, 0, NotSerialized) { Return (0x0F) }
        }
    }
}
