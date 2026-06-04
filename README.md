# PCA9641

[![Hex.pm](https://img.shields.io/hexpm/v/pca9641.svg)](https://hex.pm/packages/pca9641)
[![Apache 2.0 licensed](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

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
    {:pca9641, "~> 2.0.3"}
  ]
end
```

Documentation for the latest release can be found on
[HexDocs](https://hexdocs.pm/pca9641).

## Github Mirror

This repository is mirrored [on Github](https://github.com/jimsynz/pca9641)
from it's primary location [on my Forgejo instance](https://harton.dev/james/pca9641).
Feel free to raise issues and open PRs on Github.

## License

This software is licensed under the terms of the
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0), see the
`LICENSE.md` file included with this package for the terms.
