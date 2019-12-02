defmodule PCA9641.Registers do
  alias Circuits.I2C
  use Bitwise

  @moduledoc """
  This module provides a wrapper around the PCA9641 registers described in NXP's
  datasheet.

  Don't access these directly unless you know what you're doing. It's better to
  use the `Commands` module instead.
  """

  @type bus_address :: {I2C.bus(), I2C.address()}
  @type byte :: 0..255
  @type double :: 0..65535

  @doc """
  Register 0: ID Register. 1 byte. RO.
  """
  @spec id(bus_address) :: {:ok, byte} | {:error, term}
  def id(bus_address), do: read_register(bus_address, 0)

  @doc """
  Register 1: Control. 1 byte. RW.
  """
  @spec control(bus_address) :: {:ok, byte} | {:error, term}
  def control(bus_address), do: read_register(bus_address, 1)

  @doc """
  Register 1: Control. 1 byte. RW.
  """
  @spec control(bus_address, byte) :: :ok | {:error, term}
  def control(bus_address, byte), do: write_register(bus_address, 1, byte)

  @doc """
  Register 2: Status. 1 byte. RO.
  """
  @spec status(bus_address) :: {:ok, byte} | {:error, term}
  def status(bus_address), do: read_register(bus_address, 2)

  @doc """
  Register 3: Reserve Time. 1 byte. RW.
  """
  @spec reserve_time(bus_address) :: {:ok, byte} | {:error, term}
  def reserve_time(bus_address), do: read_register(bus_address, 3)

  @doc """
  Register 3: Reserve Time. 1 byte. RW.
  """
  @spec reserve_time(bus_address, byte) :: :ok | {:error, term}
  def reserve_time(bus_address, byte), do: write_register(bus_address, 3, byte)

  @doc """
  Register 4: Interrupt Status Register. 1 byte. RW.
  """
  @spec interrupt_status(bus_address) :: {:ok, byte} | {:error, term}
  def interrupt_status(bus_address), do: read_register(bus_address, 4)

  @doc """
  Register 4: Interrupt Status Register. 1 byte. RW.
  """
  @spec interrupt_status(bus_address, byte) :: :ok | {:error, term}
  def interrupt_status(bus_address, byte), do: write_register(bus_address, 4, byte)

  @doc """
  Register 5: Interrupt Mask Register. 1 byte. RW.
  """
  @spec interrupt_mask(bus_address) :: {:ok, byte} | {:error, term}
  def interrupt_mask(bus_address), do: read_register(bus_address, 5)

  @doc """
  Register 5: Interrupt Mask Register. 1 byte. RW.
  """
  @spec interrupt_mask(bus_address, byte) :: :ok | {:error, term}
  def interrupt_mask(bus_address, byte), do: write_register(bus_address, 5, byte)

  @doc """
  Register 6 (and 7): Mailbox. 2 bytes. RW.
  """
  @spec mailbox(bus_address) :: {:ok, double} | {:error, term}
  def mailbox(bus_address) do
    lsb = read_register(bus_address, 6)
    msb = read_register(bus_address, 7)
    (msb <<< 8) + lsb
  end

  @doc """
  Register 6 (and 7): Mailbox. 2 bytes. RW.
  """
  @spec mailbox(bus_address, double) :: :ok | {:error, term}
  def mailbox(bus_address, message) do
    msb = message >>> 8 &&& 0xFF
    lsb = message &&& 0xFF

    with :ok <- write_register(bus_address, 6, lsb),
         :ok <- write_register(bus_address, 7, msb),
         do: :ok
  end

  defp read_register({bus, address}, register, bytes \\ 1),
    do: I2C.write_read(bus, address, <<register>>, bytes)

  defp write_register({bus, address}, register, byte) when is_integer(byte),
    do: I2C.write(bus, address, <<register, byte>>)
end
