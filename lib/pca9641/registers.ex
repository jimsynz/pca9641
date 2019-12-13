defmodule PCA9641.Registers do
  alias ElixirALE.I2C
  use Bitwise

  @moduledoc """
  This module provides a wrapper around the PCA9641 registers described in NXP's
  datasheet.

  Don't access these directly unless you know what you're doing. It's better to
  use the `Commands` module instead.
  """

  @doc """
  Register 0: ID Register. 1 byte. RO.
  """
  def id(pid), do: read_register(pid, 0)

  @doc """
  Register 1: Control. 1 byte. RW.
  """
  def control(pid), do: read_register(pid, 1)
  def control(pid, byte), do: write_register(pid, 1, byte)

  @doc """
  Register 2: Status. 1 byte. RW.
  """
  def status(pid), do: read_register(pid, 2)
  def status(pid, byte), do: write_register(pid, 2, byte)

  @doc """
  Register 3: Reserve Time. 1 byte. RW.
  """
  def reserve_time(pid), do: read_register(pid, 3)
  def reserve_time(pid, byte), do: write_register(pid, 3, byte)

  @doc """
  Register 4: Interrupt Status Register. 1 byte. RW.
  """
  def interrupt_status(pid), do: read_register(pid, 4)
  def interrupt_status(pid, byte), do: write_register(pid, 4, byte)

  @doc """
  Register 5: Interrupt Mask Register. 1 byte. RW.
  """
  def interrupt_mask(pid), do: read_register(pid, 5)
  def interrupt_mask(pid, byte), do: write_register(pid, 5, byte)

  @doc """
  Register 6 (and 7): Mailbox. 2 bytes. RW.
  """
  def mailbox(pid) do
    lsb = read_register(pid, 6)
    msb = read_register(pid, 7)
    <<msb, lsb>>
  end

  def mailbox(pid, message) when is_integer(message) do
    msb = message >>> 8 &&& 0xFF
    lsb = message &&& 0xFF
    with :ok <- write_register(pid, 6, lsb), :ok <- write_register(pid, 7, msb), do: :ok
  end

  def mailbox(pid, <<msb::integer-size(8), lsb::integer-size(8)>>) do
    with :ok <- write_register(pid, 6, lsb), :ok <- write_register(pid, 7, msb), do: :ok
  end

  defp read_register(pid, register, bytes \\ 1), do: I2C.write_read(pid, <<register>>, bytes)

  defp write_register(pid, register, byte) when is_integer(byte),
    do: I2C.write(pid, <<register, byte>>)
end
