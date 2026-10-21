/*
 * billie power and volume keys: PM6350 PON (KPDPWR = power, RESIN = volume up) and PM6350 GPIO2
 * (volume down), read over SPMI by pm6350keys. Claims no resources: the driver maps the SPMI
 * arbiter itself.
 */
DefinitionBlock ("SSDT_Keys.aml", "SSDT", 2, "QCOMM ", "BILLIEKY", 1)
{
    Scope (\_SB)
    {
        Device (KEYS)
        {
            Name (_HID, "WOAT0002")
            Name (_UID, 0)

            Method (_STA, 0, NotSerialized) { Return (0x0F) }
        }
    }
}
