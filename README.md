# PCA9641

[![Build Status](https://drone.harton.dev/api/badges/james/pca9641/status.svg)](https://drone.harton.dev/james/pca9641)
[![Hex.pm](https://img.shields.io/hexpm/v/pca9641.svg)](https://hex.pm/packages/pca9641)
[![Hippocratic License HL3-FULL](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-FULL&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/full.html)

Driver for the PCA9641 2-channel I2C bus master arbiter chip.

It's a pretty sweet little chip that lets you connect two i2c mastering devices
to a shared downstream bus and makes sure that only one master can address the
downstream devices at a time. It can also relay downstream interrupts to the
mastering devices.

## Installation

`pca9641` is [available in Hex](https://hex.pm/packages/pca9641), the package
can be installed by adding `pca9641` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pca9641, "~> 2.0.1"}
  ]
end
```

Documentation for the latest release can be found on
[HexDocs](https://hexdocs.pm/pca9641) and for the `main` branch on
[docs.harton.nz](https://docs.harton.nz/james/pca9641).

## Github Mirror

This repository is mirrored [on Github](https://github.com/jimsynz/pca9641)
from it's primary location [on my Forgejo instance](https://harton.dev/james/pca9641).
Feel free to raise issues and open PRs on Github.

## License

This software is licensed under the terms of the
[HL3-FULL](https://firstdonoharm.dev), see the `LICENSE.md` file included with
this package for the terms.

This license actively proscribes this software being used by and for some
industries, countries and activities. If your usage of this software doesn't
comply with the terms of this license, then [contact me](mailto:james@harton.nz)
with the details of your use-case to organise the purchase of a license - the
cost of which may include a donation to a suitable charity or NGO.
