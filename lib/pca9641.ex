defmodule PCA9641 do
  @moduledoc """
  PCA9641 Driver for Elixir using ElixirALE.

  ## Usage:
  Add your devices to your config like so:

      config :PCA9641,
        devices: [
          %{bus: "i2c-1", address: 0x70, interrupt_pin: 7}
        ]

  Then use the functions in [PCA9641.Device] to interract with the chip.
  """

  @doc """
  Connect to an PCA9641 device.
  """
  def connect(config),
    do: Supervisor.start_child(PCA9641.Supervisor, {PCA9641.Device, config})

  @doc """
  Disconnect an PCA9641 device.
  """
  def disconnect(device_name) do
    Supervisor.terminate_child(PCA9641.Supervisor, {PCA9641.Device, device_name})
    Supervisor.delete_child(PCA9641.Supervisor, {PCA9641.Device, device_name})
  end
end
