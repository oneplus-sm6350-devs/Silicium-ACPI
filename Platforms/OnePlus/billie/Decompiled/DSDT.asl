/*
 * billie (OnePlus Nord N10 5G) - SM6350 / Lagoon
 *
 * Every address and GSIV here was derived from the device's own device tree
 * (Resources/DTBs/billie.dts), not copied from another SoC. GIC SPIs are
 * converted to ACPI GSIVs by adding 32. PDC pins are converted through
 * billie's own qcom,pdc-ranges:
 *
 *   <0x00 0x1e0 0x5e>  pdc 0..93    -> SPI 480..573
 *   <0x5e 0x261 0x1f>  pdc 94..124  -> SPI 609..639
 *   <0x7d 0x3f  0x01>  pdc 125      -> SPI 63
 *   <0x7e 0x28f 0x0c>  pdc 126..137 -> SPI 655..666
 *   <0x8a 0x8b  0x0f>  pdc 138..152 -> SPI 139..153
 *
 * Device-to-node map:
 *   UFS0 <- ufshc@1d84000     SDC2 <- sdhci@8804000
 *   SPMI <- qcom,spmi@c440000 GIO0 <- pinctrl@f100000
 *   URS0 <- ssusb@a600000
 */

DefinitionBlock ("DSDT.aml", "DSDT", 2, "QCOMM ", "SM6350 ", 3)
{
    Scope (\_SB)
    {
        /* Platform subsystem ID, used for driver matching via _SUB. */
        Name (PSUB, "IDP06350")

        Device (CPU0) { Name (_HID, "ACPI0007") Name (_UID, 0) Method (_STA) { Return (0x0F) } }
        Device (CPU1) { Name (_HID, "ACPI0007") Name (_UID, 1) Method (_STA) { Return (0x0F) } }
        Device (CPU2) { Name (_HID, "ACPI0007") Name (_UID, 2) Method (_STA) { Return (0x0F) } }
        Device (CPU3) { Name (_HID, "ACPI0007") Name (_UID, 3) Method (_STA) { Return (0x0F) } }
        Device (CPU4) { Name (_HID, "ACPI0007") Name (_UID, 4) Method (_STA) { Return (0x0F) } }
        Device (CPU5) { Name (_HID, "ACPI0007") Name (_UID, 5) Method (_STA) { Return (0x0F) } }
        Device (CPU6) { Name (_HID, "ACPI0007") Name (_UID, 6) Method (_STA) { Return (0x0F) } }
        Device (CPU7) { Name (_HID, "ACPI0007") Name (_UID, 7) Method (_STA) { Return (0x0F) } }

        /*
         * TLMM pin controller. Declared before its consumers because SDC2
         * references it by name from a GpioInt/GpioIo descriptor.
         *
         *   reg        = <0xf100000 0x300000>
         *   interrupts = <0 0xd0..0xd8 4>  ->  SPI 208..216  ->  GSIV 240..248
         *
         * No _DSM: the pin-count DSM that Lahaina DSDTs carry reports 0x140,
         * which matches neither that SoC's pin count nor any value derivable
         * for Lagoon, so it is left out rather than guessed.
         */
        Device (GIO0)
        {
            Name (_HID, "QCOM1A0C")
            Alias (\_SB.PSUB, _SUB)
            Name (_UID, Zero)

            Name (_CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite, 0x0F100000, 0x00300000)

                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F0 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F1 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F2 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F3 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F4 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F5 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F6 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F7 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , ) { 0x000000F8 }
            })

            Method (_STA, 0, NotSerialized) { Return (0x0F) }
        }

        /*
         * SPMI PMIC arbiter v5. billie splits the space into five windows:
         *
         *   core   0x0c440000 0x001100   chnls  0x0c600000 0x2000000
         *   obsrvr 0x0e600000 0x100000   intr   0x0e700000 0x00a0000
         *   cnfg   0x0c40a000 0x026000
         *
         * All five fall inside 0x0c400000 + 0x02800000, which is the single
         * window Qualcomm's own DSDTs declare. qcom,ee = 0, qcom,channel = 0.
         *
         * CONF is the arbiter descriptor the Windows SPMI driver reads. Its
         * last eight bytes are the base and length above, big-endian; the
         * preceding bytes are the PMIC-arb v5 layout, which Lagoon shares
         * with Lahaina (same compatible, same reg-names, same ordering).
         */
        Device (SPMI)
        {
            Name (_HID, "QCOM1A0B")
            Name (_CID, "PNP0CA2")
            Alias (\_SB.PSUB, _SUB)
            Name (_UID, One)
            Name (_CCA, Zero)

            Name (_CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite, 0x0C400000, 0x02800000)
            })

            Name (CONF, Buffer ()
            {
                0x00,
                0x01,
                0x01,
                0x01, 0xFF,
                0x00,
                0x02, 0x00,
                0x0A,
                0x07,
                0x04,
                0x07,
                0x01, 0xFF,
                0x10,
                0x01, 0x00,
                0x01,
                0x0C, 0x40, 0x00, 0x00,
                0x02, 0x80, 0x00, 0x00
            })

            Method (_STA, 0, NotSerialized) { Return (0x0F) }
        }

        /*
         * UFS host controller - the boot device. Without this Windows has no
         * storage.
         *
         *   reg        = <0x1d84000 0x3000  0x1d90000 0x8000>  (ufs_mem + ufs_ice)
         *   interrupts = <0 0x109 4>  ->  SPI 265  ->  GSIV 297
         *   0x14000 spans both register windows, matching the Rennell reference.
         */
        Device (UFS0)
        {
            Name (_HID, "QCOM24A5")
            Alias (\_SB.PSUB, _SUB)
            Name (_UID, Zero)
            Name (_CCA, Zero)

            Method (_CRS, 0, NotSerialized)
            {
                Name (RBUF, ResourceTemplate ()
                {
                    Memory32Fixed (ReadWrite, 0x01D84000, 0x00014000)
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, , , )
                    {
                        0x00000129,
                    }
                })
                Return (RBUF)
            }

            /* LUN 4 holds the GPT we boot from (gEfiUfsLU4Guid). */
            Device (DEV0)
            {
                Method (_ADR, 0, NotSerialized) { Return (0x08) }
                Method (_RMV, 0, NotSerialized) { Return (Zero) }
            }
        }

        /*
         * SD card slot.
         *
         *   reg        = <0x8804000 0x1000>
         *   interrupts = <0 0xcc 4>  (hc_irq)  ->  SPI 204  ->  GSIV 236
         *                <0 0xde 4>  (pwr_irq) is a Linux-only wakeup line and
         *                            is not declared here.
         *   card detect = gpio94, bias-pull-up  (/soc/pinctrl@f100000/cd_on)
         *
         * _STA returns 0. The slot never enumerates under our UEFI either, and
         * the stock device tree ships this node as status = "disabled", so it is
         * described but not reported present. Flip to 0x0F once SdccDxe can see
         * a card.
         */
        Device (SDC2)
        {
            Name (_HID, "QCOM2466")
            Alias (\_SB.PSUB, _SUB)
            Name (_UID, One)
            Name (_CCA, Zero)
            Name (_DEP, Package () { \_SB.GIO0 })

            Name (_CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite, 0x08804000, 0x00001000)

                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, , , ) { 0x000000EC }

                GpioInt (Edge, ActiveBoth, Shared, PullUp, 0x1388, "\\_SB.GIO0", , ) { 0x5E }
                GpioIo (Shared, PullUp, 0x0000, 0x0000, IoRestrictionNone, "\\_SB.GIO0", , ) { 0x5E }
            })

            Method (_STA, 0, NotSerialized) { Return (Zero) }
        }

        /*
         * USB role switch over the single Type-C port. USB0 is the xHCI host
         * role, UFN0 the device role.
         *
         *   ssusb@a600000 reg = <0xa600000 0x200000>, dr_mode = "drd"
         *   dwc3@a600000  interrupts    = <0 0x85 4>  -> SPI 133 -> GSIV 165
         *   pwr_event_irq (GIC)         = <0 0x82 4>  -> SPI 130 -> GSIV 162
         *   dp_hs_phy_irq (PDC pin 14)  -> SPI 494 -> GSIV 526
         *   dm_hs_phy_irq (PDC pin 15)  -> SPI 495 -> GSIV 527
         *   ss_phy_irq    (PDC pin 17)  -> SPI 497 -> GSIV 529
         *
         * maximum-speed = "high-speed" in the device tree, so the port is USB 2.0
         * only despite the SS PHY being present; _UPC reports a Type-C receptacle
         * rather than a SuperSpeed one.
         *
         * Host mode does not work under our UEFI (no VBUS). That is a firmware
         * limitation, not a description error, so this node is reported present.
         */
        Device (URS0)
        {
            Name (_HID, "QCOM0497")
            Name (_CID, "PNP0CA1")
            Alias (\_SB.PSUB, _SUB)
            Name (_UID, Zero)
            Name (_CCA, Zero)

            Name (_CRS, ResourceTemplate ()
            {
                Memory32Fixed (ReadWrite, 0x0A600000, 0x000FFFFF)
            })

            Method (_STA, 0, NotSerialized) { Return (0x0F) }

            Device (USB0)
            {
                Name (_ADR, Zero)
                Name (_S0W, 0x03)

                Name (_CRS, ResourceTemplate ()
                {
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , )        { 0x000000A5 }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, SharedAndWake, , , ) { 0x000000A2 }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, SharedAndWake, , , ) { 0x00000211 }
                    Interrupt (ResourceConsumer, Edge, ActiveHigh, SharedAndWake, , , )  { 0x0000020F }
                    Interrupt (ResourceConsumer, Edge, ActiveHigh, SharedAndWake, , , )  { 0x0000020E }
                })

                Device (RHUB)
                {
                    Name (_ADR, Zero)

                    Device (PRT1)
                    {
                        Name (_ADR, One)

                        /* Type-C USB 2.0 receptacle, user visible, bottom edge. */
                        Name (_UPC, Package () { One, 0x09, Zero, Zero })
                    }
                }

                Method (PHYC, 0, NotSerialized)
                {
                    Name (CFG0, Package () {})
                    Return (CFG0)
                }
            }

            Device (UFN0)
            {
                Name (_ADR, One)
                Name (_S0W, 0x03)

                Name (_CRS, ResourceTemplate ()
                {
                    Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, , , )        { 0x000000A5 }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, SharedAndWake, , , ) { 0x000000A2 }
                    Interrupt (ResourceConsumer, Level, ActiveHigh, SharedAndWake, , , ) { 0x00000211 }
                    Interrupt (ResourceConsumer, Edge, ActiveHigh, SharedAndWake, , , )  { 0x0000020F }
                    Interrupt (ResourceConsumer, Edge, ActiveHigh, SharedAndWake, , , )  { 0x0000020E }
                })

                Name (_UPC, Package () { One, 0x09, Zero, Zero })

                Method (PHYC, 0, NotSerialized)
                {
                    Name (CFG0, Package () {})
                    Return (CFG0)
                }
            }
        }
    }
}
