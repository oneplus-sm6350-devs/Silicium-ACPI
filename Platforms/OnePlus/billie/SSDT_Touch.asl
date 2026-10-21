/*
 * billie touchscreen: Himax HX83112F on QUP0 SE0 (SPI), CS gpio3, RST gpio21, IRQ gpio22.
 * Claims no resources: a52q's DSDT (currently shipped as billie's DSDT) declares I2C1 on the
 * same SE0 block, so woatouch maps SE0 and the TLMM tiles itself.
 */
DefinitionBlock ("SSDT_Touch.aml", "SSDT", 2, "QCOMM ", "BILLIETS", 1)
{
    Scope (\_SB)
    {
        Device (TCH0)
        {
            Name (_HID, "WOAT0001")
            Name (_UID, 0)

            Method (_STA, 0, NotSerialized) { Return (0x0F) }
        }
    }
}
