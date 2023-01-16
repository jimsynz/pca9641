# PCA9641

[![pipeline status](https://gitlab.com/jimsy/pca9641/badges/main/pipeline.svg)](https://gitlab.com/jimsy/pca9641/commits/main)
[![Hex.pm](https://img.shields.io/hexpm/v/pca9641.svg)](https://hex.pm/packages/pca9641)
[![Hippocratic License HL3-FULL](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-FULL&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/full.html)

Driver for the PCA9641 2-channel I2C bus master arbiter chip.

It's a pretty sweet little chip that lets you connect two i2c mastering devices
to a shared downstream bus and makes sure that only one master can address the
downstream devices at a time.  It can also relay downstream interrupts to the
mastering devices.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pca9641` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pca9641, "~> 1.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pca9641](https://hexdocs.pm/pca9641).

## License

This software is licensed under the terms of the
[HL3-FULL](https://firstdonoharm.dev), see the `LICENSE.md` file included with
this package for the terms.

This license actively proscribes this software being used by and for some
industries, countries and activities.  If your usage of this software doesn't
comply with the terms of this license, then [contact me](mailto:james@harton.nz)
with the details of your use-case to organise the purchase of a license - the
cost of which may include a donation to a suitable charity or NGO.
