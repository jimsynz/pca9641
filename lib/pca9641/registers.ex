defmodule PCA9641.Registers do
  use Wafer.Registers

  @moduledoc """
  This module provides a wrapper around the PCA9641 registers described in NXP's
  datasheet.
  """

  defregister(:id, 0x00, :ro, 1)
  defregister(:control, 0x01, :rw, 1)
  defregister(:status, 0x02, :rw, 1)
  defregister(:reserve_time, 0x03, :rw, 1)
  defregister(:interrupt_status, 0x04, :rw, 1)
  defregister(:interrupt_mask, 0x05, :rw, 1)
  defregister(:mailbox, 0x06, :rw, 2)
end
