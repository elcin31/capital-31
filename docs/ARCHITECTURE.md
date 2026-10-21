# CAPITAL / Android

Godot 4.6.3, GDScript, OpenGL ES 3 compatibility renderer, landscape 1440×810
logical canvas with responsive safe area. No network permissions, backend, ads,
analytics or paid APIs. Monetary values are integer euro cents.

`core/game.gd` owns state, commands and the fixed hourly clock.
`simulation/ledger.gd` is the sole gateway for corporate transactions. Every
posting balances assets against liabilities and equity and records its cash flow.
`simulation/economy.gd` advances daily markets, companies, receivables, taxes,
payroll, amortization, competitors, cycles, and branches.
`simulation/office.gd` validates grid placement and BFS reachability.
`simulation/negotiation.gd` handles offline investor decisions and dilution.
`core/save_store.gd` stores versioned SHA-256 checked JSON envelope with lossless, object-free Godot Variant payload with a backup and
atomic rename. Simulation does not depend on render FPS; saves retain the seed,
hour, world, company history and founder career.
`render/` owns city, cutaway offices, modular people, camera and animation.
`ui/` provides Russian game screens and sends commands, without editing money.

Android uses a signed test APK, ARM64, ARMv7 and x86_64 (for the Android emulator), API 24 minimum; API 36 target. The exact
export settings and test results accompany the final artifact. Performance on a
physical Redmi Note 12 requires measurement on that device.
