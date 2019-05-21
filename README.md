# B21 Soaring

This is an X-Plane 'global' plugin written using the SASL Lua system.

The plugin adds soaring-related capabilities to X-Plane. These include:

1. total energy 'rate of climb' as the following global datarefs:
    * b21_soaring/total_energy_mps (float, meters per second)
    * b21_soaring/total_energy_fpm (float, feet per minute)
    * b21_soaring/total_energy_kts (float, knots)

2. A 'soaring analysis' window, available via plugin menu, which shows:
    * wing angle of attack i.e. alpha (float, degrees)
    * airspeed (float, m/s, knots, kph - click window to change)
    * te climb (float, m/s, knots - click window to change)
    * glide ratio (float)
    