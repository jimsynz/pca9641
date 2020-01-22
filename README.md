# PCA9641

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
    {:pca9641, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/pca9641](https://hexdocs.pm/pca9641).

