defmodule PCA9641.Commands do
  alias PCA9641.Registers
  alias Circuits.I2C
  use Bitwise

  @moduledoc """
  Wrapper around the `Registers` module to handle sending commands to and from
  the device.
  """

  @type bus_address :: {I2C.bus(), I2C.address()}

  @doc false
  @spec start_link(I2C.bus(), I2C.address()) :: {:ok, bus_address} | {:error, term}
  def start_link(bus, address) when is_integer(address) and address >= 0 and address <= 127 do
    case I2C.open(bus) do
      {:ok, bus} -> {:ok, {bus, address}}
      error -> error
    end
  end

  @doc false
  @spec release(bus_address) :: :ok
  def release({bus, _address}), do: I2C.release(bus)

  @doc """
  Retrieve the device ID.  For PCA9641 this should be 0x38.
  """
  @spec id(bus_address) :: {:ok, non_neg_integer} | {:error, term}
  def id(bus_address) do
    <<id>> = Registers.id(bus_address)
    {:ok, id}
  end

  @doc """
  PRIORITY

  Master can set this register bit for setting priority of the winner when two
  masters request the downstream bus at the same time.
  """
  @spec priority?(bus_address) :: boolean
  def priority?(bus_address), do: read_bit_as_boolean(bus_address, :control, 7)

  @doc """
  PRIORITY

  Master can set this register bit for setting priority of the winner when two
  masters request the downstream bus at the same time.
  """
  @spec priority(bus_address, boolean) :: :ok | {:error, term}
  def priority(bus_address, value), do: write_bit_as_boolean(bus_address, :control, 7, value)

  @doc """
  SMBUS_DIS

  When PCA9641 detects an SMBus time-out, if this bit is set, PCA9641 will
  disconnect I2C-bus from master to downstream bus.

  - `false` -> Normal operation.
  - `true` -> Connectivity between master and downstream bus will be
    disconnected upon detecting an SMBus time-out condition.
  """
  @spec downstream_disconnect_on_timeout?(bus_address) :: boolean
  def downstream_disconnect_on_timeout?(bus_address),
    do: read_bit_as_boolean(bus_address, :control, 6)

  @doc """
  SMBUS_DIS

  When PCA9641 detects an SMBus time-out, if this bit is set, PCA9641 will
  disconnect I2C-bus from master to downstream bus.

  - `false` -> Normal operation.
  - `true` -> Connectivity between master and downstream bus will be
    disconnected upon detecting an SMBus time-out condition.
  """
  @spec downstream_disconnect_on_timeout(bus_address, boolean) :: :ok | {:error, term}
  def downstream_disconnect_on_timeout(bus_address, value),
    do: write_bit_as_boolean(bus_address, :control, 6, value)

  @doc """
  IDLE_TIMER_DIS

  After RES_TIME is expired, I2C-bus idle for more than 100 ms, PCA9641 will
  disconnect master from downstream bus and takes away its grant if this
  register bit is enabled. This IDLE_TIMER_DIS function also applies when there
  is a grant of a request with zero value on RES_TIME.

  - `false` -> Normal operation.
  - `true` -> Enable 100 ms idle timer. After reserve timer expires or if
    reserve timer is disabled, if the downstream bus is idle for more than 100
    ms, the connection between master and downstream bus will be disconnected.
  """
  @spec idle_timer_disconnect?(bus_address) :: boolean
  def idle_timer_disconnect?(bus_address), do: read_bit_as_boolean(bus_address, :control, 5)

  @doc """
  IDLE_TIMER_DIS

  After RES_TIME is expired, I2C-bus idle for more than 100 ms, PCA9641 will
  disconnect master from downstream bus and takes away its grant if this
  register bit is enabled. This IDLE_TIMER_DIS function also applies when there
  is a grant of a request with zero value on RES_TIME.

  - `false` -> Normal operation.
  - `true` -> Enable 100 ms idle timer. After reserve timer expires or if
    reserve timer is disabled, if the downstream bus is idle for more than 100
    ms, the connection between master and downstream bus will be disconnected.
  """
  @spec idle_timer_disconnect(bus_address, boolean) :: :ok | {:error, term}
  def idle_timer_disconnect(bus_address, value),
    do: write_bit_as_boolean(bus_address, :control, 5, value)

  @doc """
  SMBUS_SWRST

  Non-granted or granted master sends a soft reset, if this bit is set, PCA9641
  sets clock LOW for 35 ms following reset of all register values to defaults.

  - `false` -> Normal operation.
  - `true` -> Enable sending SMBus time-out to downstream bus, after receiving a
    general call soft reset from master.
  """
  @spec smbus_software_reset?(bus_address) :: boolean
  def smbus_software_reset?(bus_address), do: read_bit_as_boolean(bus_address, :control, 4)

  @doc """
  SMBUS_SWRST

  Non-granted or granted master sends a soft reset, if this bit is set, PCA9641
  sets clock LOW for 35 ms following reset of all register values to defaults.

  - `false` -> Normal operation.
  - `true` -> Enable sending SMBus time-out to downstream bus, after receiving a
    general call soft reset from master.
  """
  @spec smbus_software_reset(bus_address, boolean) :: :ok | {:error, term}
  def smbus_software_reset(bus_address, value),
    do: write_bit_as_boolean(bus_address, :control, 4, value)

  @doc """
  BUS_INIT

  Bus initialization for PCA9641 sends one clock out and checks SDA signal. If
  SDA is HIGH, PCA9641 sends a ‘not acknowledge’ and a STOP condition. The
  BUS_INIT function is completed. If SDA is LOW, PCA9641 sends other clock out
  and checks SDA again. The PCA9641 will send out 9 clocks (maximum), and if SDA
  is still LOW, PCA9641 determines the bus initialization has failed.

  - `false` -> Normal operation.
  - `true` -> Start initialization on next bus connect function to downstream
    bus.
  """
  @spec bus_init?(bus_address) :: boolean
  def bus_init?(bus_address), do: read_bit_as_boolean(bus_address, :control, 3)

  @doc """
  BUS_INIT

  Bus initialization for PCA9641 sends one clock out and checks SDA signal. If
  SDA is HIGH, PCA9641 sends a ‘not acknowledge’ and a STOP condition. The
  BUS_INIT function is completed. If SDA is LOW, PCA9641 sends other clock out
  and checks SDA again. The PCA9641 will send out 9 clocks (maximum), and if SDA
  is still LOW, PCA9641 determines the bus initialization has failed.

  - `false` -> Normal operation.
  - `true` -> Start initialization on next bus connect function to downstream
    bus.
  """
  @spec bus_init(bus_address, boolean) :: :ok | {:error, term}
  def bus_init(bus_address, value), do: write_bit_as_boolean(bus_address, :control, 3, value)

  @doc """
  BUS_CONNECT

  Connectivity between master and downstream bus; the internal switch connects
  I2C-bus from master to downstream bus only if LOCK_GRANT = 1.

  - `false` -> Do not connect I2C-bus from master to downstream bus.
  - `true` -> Connect downstream bus; the internal switch is closed only if LOCK_GRANT = 1.
  """
  @spec bus_connect?(bus_address) :: boolean
  def bus_connect?(bus_address), do: read_bit_as_boolean(bus_address, :control, 2)

  @doc """
  BUS_CONNECT

  Connectivity between master and downstream bus; the internal switch connects
  I2C-bus from master to downstream bus only if LOCK_GRANT = 1.

  - `false` -> Do not connect I2C-bus from master to downstream bus.
  - `true` -> Connect downstream bus; the internal switch is closed only if LOCK_GRANT = 1.
  """
  @spec bus_connect(bus_address, boolean) :: :ok | {:error, term}
  def bus_connect(bus_address, value), do: write_bit_as_boolean(bus_address, :control, 2, value)

  @doc """
  LOCK_GRANT

  This is a status read only register bit. Lock grant status register bit
  indicates the ownership between reading master and the downstream bus. If this
  register bit is 1, the reading master has owned the downstream bus. If this
  register bit is zero, the reading master has not owned the downstream bus.

  - `false` -> This master does not have a lock on the downstream bus.
  - `true` -> This master has a lock on the downstream bus.
  """
  @spec lock_grant?(bus_address) :: boolean
  def lock_grant?(bus_address), do: read_bit_as_boolean(bus_address, :control, 1)

  @doc """
  LOCK_REQ

  Lock request register bit is for a master requesting the downstream bus when
  it does not have a lock on downstream bus. When a master has a lock on
  downstream bus, it can give up the ownership by writing zero to LOCK_REQ
  register bit. When LOCK_REQ becomes zero, LOCK_GRANT bit becomes zero and the
  internal switch will be open.

  - `false` -> Master is not requesting a lock on the downstream bus or giving
    up the lock if master had a lock on the downstream bus.
  - `true` -> Master is requesting a lock on the downstream bus.
  """
  @spec lock_request?(bus_address) :: boolean
  def lock_request?(bus_address), do: read_bit_as_boolean(bus_address, :control, 0)

  @doc """
  LOCK_REQ

  Lock request register bit is for a master requesting the downstream bus when
  it does not have a lock on downstream bus. When a master has a lock on
  downstream bus, it can give up the ownership by writing zero to LOCK_REQ
  register bit. When LOCK_REQ becomes zero, LOCK_GRANT bit becomes zero and the
  internal switch will be open.

  - `false` -> Master is not requesting a lock on the downstream bus or giving
    up the lock if master had a lock on the downstream bus.
  - `true` -> Master is requesting a lock on the downstream bus.
  """
  @spec lock_request(bus_address, boolean) :: :ok | {:error, term}
  def lock_request(bus_address, value), do: write_bit_as_boolean(bus_address, :control, 0, value)

  @doc """
  SDA_IO

  SDA becomes I/O pin; master can read or write to this register bit. If master
  reads this bit, the value is the state of the downstream SDA pin. Zero value
  means SDA is LOW, and one means SDA pin is HIGH. When master writes ‘0’ to
  this register bit, the downstream SDA pin will assert LOW. If master writes‘1’
  to this register bit, the downstream SDA pin will be pulled HIGH. Remark: SDA
  becomes I/O pin only when BUS_CONNECT = 0 and LOCK_GRANT = 1.

  - `false` -> When read, indicates the SDA pin of the downstream bus is LOW.
    When written, PCA9641 drives SDA pin of downstream bus LOW.
  - `true` -> When read, indicates the SDA pin of the downstream bus is HIGH.
    When written, PCA9641 drives SDA pin of the downstream bus HIGH.
  """
  @spec sda_becomes_io?(bus_address) :: boolean
  def sda_becomes_io?(bus_address), do: read_bit_as_boolean(bus_address, :status, 7)

  @doc """
  SDA_IO

  SDA becomes I/O pin; master can read or write to this register bit. If master
  reads this bit, the value is the state of the downstream SDA pin. Zero value
  means SDA is LOW, and one means SDA pin is HIGH. When master writes ‘0’ to
  this register bit, the downstream SDA pin will assert LOW. If master writes‘1’
  to this register bit, the downstream SDA pin will be pulled HIGH. Remark: SDA
  becomes I/O pin only when BUS_CONNECT = 0 and LOCK_GRANT = 1.

  - `false` -> When read, indicates the SDA pin of the downstream bus is LOW.
    When written, PCA9641 drives SDA pin of downstream bus LOW.
  - `true` -> When read, indicates the SDA pin of the downstream bus is HIGH.
    When written, PCA9641 drives SDA pin of the downstream bus HIGH.
  """
  @spec sda_becomes_io(bus_address, boolean) :: :ok | {:error, term}
  def sda_becomes_io(bus_address, value), do: write_bit_as_boolean(bus_address, :status, 7, value)

  @doc """
  SCL_IO

  SCL becomes I/O pin; master can read or write to this register bit. If master
  reads this bit, the value is the state of the downstream SCL pin. Zero value
  means SCL is LOW, and one means SCL pin is HIGH. When master writes ‘0’ to
  this register bit, the downstream SCL pin will assert LOW. If master writes‘1’
  to this register bit, the downstream SCL pin will be pulled HIGH. Remark: SCL
  becomes I/O pin only when BUS_CONNECT = 0 and LOCK_GRANT = 1.

  - `false` -> When read, shows the SCL pin of the downstream bus is LOW. When
    written, PCA9641 drives SCL pin of downstream bus LOW.
  - `true` -> When read, shows the SCL pin of the downstream bus is HIGH. When
    written, PCA9641 drives SCL pin of the downstream bus HIGH.
  """
  @spec scl_becomes_io?(bus_address) :: boolean
  def scl_becomes_io?(bus_address), do: read_bit_as_boolean(bus_address, :status, 6)

  @doc """
  SCL_IO

  SCL becomes I/O pin; master can read or write to this register bit. If master
  reads this bit, the value is the state of the downstream SCL pin. Zero value
  means SCL is LOW, and one means SCL pin is HIGH. When master writes ‘0’ to
  this register bit, the downstream SCL pin will assert LOW. If master writes‘1’
  to this register bit, the downstream SCL pin will be pulled HIGH. Remark: SCL
  becomes I/O pin only when BUS_CONNECT = 0 and LOCK_GRANT = 1.

  - `false` -> When read, shows the SCL pin of the downstream bus is LOW. When
    written, PCA9641 drives SCL pin of downstream bus LOW.
  - `true` -> When read, shows the SCL pin of the downstream bus is HIGH. When
    written, PCA9641 drives SCL pin of the downstream bus HIGH.
  """
  @spec scl_becomes_io(bus_address, boolean) :: :ok | {:error, term}
  def scl_becomes_io(bus_address, value), do: write_bit_as_boolean(bus_address, :status, 6, value)

  @doc """
  TEST_INT

  Test interrupt output pin; a master can send an interrupt to itself by writing
  ‘1’ to this register bit. Writing ‘0’ to this register bit has no effect. To
  clear this interrupt, master must write ‘1’ to TEST_INT_INT in Interrupt
  Status register.

  - `false` -> Normal operation.
  - `true` -> Causes PCA9641 INT pin to go LOW if not masked by TEST_INT_INT in
    Interrupt Mask register. Allows this master to invoke its Interrupt Service
    Routine to handle housekeeping tasks.
  """
  @spec test_interrupt_pin(bus_address, boolean) :: :ok | {:error, term}
  def test_interrupt_pin(bus_address, value),
    do: write_bit_as_boolean(bus_address, :status, 5, value)

  @doc """
  MBOX_FULL

  This is a read-only status register bit. If this bit is ‘0’, it indicates no
  data is available in the mail box. If it is ‘1’, it indicates new data is
  available in the mail box.

  - `false` -> No data is available for *this* master.
  - `true` -> Mailbox contains data for *this* master from the other master.
  """
  @spec mailbox_full?(bus_address) :: boolean
  def mailbox_full?(bus_address), do: read_bit_as_boolean(bus_address, :status, 4)

  @doc """
  MBOX_EMPTY

  This is a read-only status register bit. If this bit is ‘0’, it indicates
  other master mailbox is full, and this master cannot send more data to other
  master mailbox. If it is ‘1’, it indicates other master is empty and this
  master can send data to other master mailbox.

  - `false` -> *Other* master mailbox is full; wait until *other* master reads
    data.
  - `true` -> *Other* master mailbox is empty. *Other* master has read previous
    data and it is permitted to write new data.
  """
  @spec mailbox_empty?(bus_address) :: boolean
  def mailbox_empty?(bus_address), do: read_bit_as_boolean(bus_address, :status, 3)

  @doc """
  BUS_HUNG

  This is a read-only status register bit. If this register bit is ‘0’, it
  indicates the bus is in normal condition. If this bit is ‘1’, it indicates the
  bus is hung. The hung bus means SDA signal is LOW and SCL signal does not
  toggle for more than 500 ms or SCL is LOW for 500 ms.

  - `false` -> Normal operation.
  - `true` -> Downstream bus hung; when SDA signal is LOW and SCL signal does
    not toggle for more than 500 ms or SCL is LOW for 500 ms.
  """
  @spec bus_hung?(bus_address) :: boolean
  def bus_hung?(bus_address), do: read_bit_as_boolean(bus_address, :status, 2)

  @doc """
  BUS_INIT_FAIL

  This is a read-only status register bit. If this register bit is ‘0’, it
  indicates the bus initialization function has passed. The downstream bus is in
  idle mode (SCL and SDA are HIGH). If this register bit is ‘1’, it indicates
  the bus initialization function has failed. The SDA signal could be stuck LOW.

  - `false` -> Normal operation.
  - `true` -> Bus initialization has failed. SDA still LOW, the downstream bus
    cannot recover.
  """
  @spec bus_initialisation_failed?(bus_address) :: boolean
  def bus_initialisation_failed?(bus_address), do: read_bit_as_boolean(bus_address, :status, 1)

  @doc """
  OTHER_LOCK

  This is a status read-only register bit. Other master lock status indicates
  the ownership between other master and the downstream bus. If this register
  bit is ‘1’, the other master has owned the downstream bus. If this register
  bit is ‘0’, the other master does not own the downstream bus.

  - `false` -> The other master does not have a lock on the downstream bus.
  - `true` -> The other master has a lock on the downstream bus.
  """
  @spec other_lock?(bus_address) :: boolean
  def other_lock?(bus_address), do: read_bit_as_boolean(bus_address, :status, 0)

  @doc """
  RES_TIME

  Reserve timer. Changes during LOCK_GRANT = 1 will have no effect.

  Returns `{:ok, n}` where `n` is the number if milliseconds remaining in the
  reservation.
  """
  @spec reserve_time(bus_address) :: {:ok, non_neg_integer} | {:error, term}
  def reserve_time(bus_address) do
    <<ms>> = Registers.reserve_time(bus_address)
    {:ok, ms}
  end

  @doc """
  RES_TIME

  Reserve timer. Changes during LOCK_GRANT = 1 will have no effect.

  `ms` is the number of milliseconds remaining in the reservation.
  """
  @spec reserve_time(bus_address) :: {:ok, non_neg_integer} | {:error, term}
  def reserve_time(bus_address, ms) when is_integer(ms) and ms >= 0 and ms <= 0xFF,
    do: Registers.reserve_time(bus_address, ms)

  def reserve_time(_bus_address, _ms), do: {:error, "Invalid milliseconds value"}

  @doc """
  BUS_HUNG_INT

  Indicates to both masters that SDA signal is LOW and SCL signal does not
  toggle for more than 500 ms or SCL is LOW for 500 ms.

  - `false` -> No interrupt generated; normal operation.
  - `true` -> Interrupt generated; downstream bus cannot recover; when SDA
    signal is LOW and SCL signal does not toggle for more than 500 ms or SCL is
    LOW for 500 ms,
  """
  @spec bus_hung_interrupt?(bus_address) :: boolean
  def bus_hung_interrupt?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_status, 6)

  @doc """
  BUS_HUNG_INT

  Indicates to both masters that SDA signal is LOW and SCL signal does not
  toggle for more than 500 ms or SCL is LOW for 500 ms.

  - `false` -> No interrupt generated; normal operation.
  - `true` -> Interrupt generated; downstream bus cannot recover; when SDA
    signal is LOW and SCL signal does not toggle for more than 500 ms or SCL is
    LOW for 500 ms,
  """
  @spec bus_hung_interrupt(bus_address, boolean) :: :ok | {:error, term}
  def bus_hung_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 6, value)

  @doc """
  MBOX_FULL_INT

  Indicates the mailbox has new mail.

  - `false` -> No interrupt generated; mailbox is not full.
  - `true` -> Interrupt generated; mailbox full.
  """
  @spec mailbox_full_interrupt?(bus_address) :: boolean
  def mailbox_full_interrupt?(bus_address),
    do: read_bit_as_boolean(bus_address, :interrupt_status, 5)

  @doc """
  MBOX_FULL_INT

  Indicates the mailbox has new mail.

  - `false` -> No interrupt generated; mailbox is not full.
  - `true` -> Interrupt generated; mailbox full.
  """
  @spec mailbox_full_interrupt(bus_address, boolean) :: :ok | {:error, term}
  def mailbox_full_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 5, value)

  @doc """
  MBOX_EMPTY_INT

  Indicates the sent mail is empty, other master has read the mail.

  - `false` -> No interrupt generated; sent mail is not empty.
  - `true` -> Interrupt generated; mailbox is empty.
  """
  @spec mailbox_empty_interrupt?(bus_address) :: boolean
  def mailbox_empty_interrupt?(bus_address),
    do: read_bit_as_boolean(bus_address, :interrupt_status, 4)

  @doc """
  MBOX_EMPTY_INT

  Indicates the sent mail is empty, other master has read the mail.

  - `false` -> No interrupt generated; sent mail is not empty.
  - `true` -> Interrupt generated; mailbox is empty.
  """
  @spec mailbox_empty_interrupt(bus_address, boolean) :: :ok | {:error, term}
  def mailbox_empty_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 4, value)

  @doc """
  TEST_INT_INT

  Indicates this master has sent an interrupt to itself.

  - `false` -> No interrupt generated; master has not set the TEST_INT bit in
    STATUS register.
  - `true` -> Interrupt generated; master activates its interrupt pin via the
    TEST_INT bit in STATUS register.
  """
  @spec test_interrupt_pin_interrupt?(bus_address) :: boolean
  def test_interrupt_pin_interrupt?(bus_address),
    do: read_bit_as_boolean(bus_address, :interrupt_status, 3)

  @doc """
  TEST_INT_INT

  Indicates this master has sent an interrupt to itself.

  - `false` -> No interrupt generated; master has not set the TEST_INT bit in
    STATUS register.
  - `true` -> Interrupt generated; master activates its interrupt pin via the
    TEST_INT bit in STATUS register.
  """
  @spec test_interrupt_pin_interrupt(bus_address, true) :: :ok | {:error, term}
  def test_interrupt_pin_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 2, value)

  @doc """
  LOCK_GRANT_INT

  Indicates the master has a lock (ownership) on the downstream bus.

  - `false` -> No interrupt generated; this master does not have a lock on the
    downstream bus.
  - `true` -> Interrupt generated; this master has a lock on the downstream bus.
  """
  @spec lock_grant_interrupt?(bus_address) :: boolean
  def lock_grant_interrupt?(bus_address),
    do: read_bit_as_boolean(bus_address, :interrupt_status, 2)

  @doc """
  LOCK_GRANT_INT

  Indicates the master has a lock (ownership) on the downstream bus.

  - `false` -> No interrupt generated; this master does not have a lock on the
    downstream bus.
  - `true` -> Interrupt generated; this master has a lock on the downstream bus.
  """
  @spec lock_grant_interrupt(bus_address, boolean) :: :ok | {:error, term}
  def lock_grant_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 2, value)

  @doc """
  BUS_LOST_INT

  Indicates the master has involuntarily lost the ownership of the downstream
  bus.

  - `false` -> No interrupt generated; this master is controlling the downstream
    bus.
  - `true` -> Interrupt generated; this master has involuntarily lost the
    control of the downstream bus.
  """
  @spec bus_lost_interrupt?(bus_address) :: boolean
  def bus_lost_interrupt?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_status, 1)

  @doc """
  BUS_LOST_INT

  Indicates the master has involuntarily lost the ownership of the downstream
  bus.

  - `false` -> No interrupt generated; this master is controlling the downstream
    bus.
  - `true` -> Interrupt generated; this master has involuntarily lost the
    control of the downstream bus.
  """
  @spec bus_lost_interrupt(bus_address, boolean) :: :ok | {:error, term}
  def bus_lost_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 1, value)

  @doc """
  INT_IN_INT

  Indicates that there is an interrupt from the downstream bus to both the
  granted and non-granted masters.

  - `false` -> No interrupt on interrupt input pin INT_IN.
  - `true` -> Interrupt on interrupt input pin INT_IN.
  """
  @spec interupt_in_interrupt?(bus_address) :: boolean
  def interupt_in_interrupt?(bus_address),
    do: read_bit_as_boolean(bus_address, :interrupt_status, 0)

  @doc """
  INT_IN_INT

  Indicates that there is an interrupt from the downstream bus to both the
  granted and non-granted masters.

  - `false` -> No interrupt on interrupt input pin INT_IN.
  - `true` -> Interrupt on interrupt input pin INT_IN.
  """
  @spec interupt_in_interrupt(bus_address, boolean) :: :ok | {:error, term}
  def interupt_in_interrupt(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_status, 0, value)

  @doc """
  BUS_HUNG_MSK

  - `false` -> Enable output interrupt when BUS_HUNG function is set.
  - `true` -> Disable output interrupt when BUS_HUNG function is set.
  """
  @spec bus_hung_mask?(bus_address) :: boolean
  def bus_hung_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 6)

  @doc """
  MBOX_FULL_MSK

  - `false` -> Enable output interrupt when MBOX_FULL function is set.
  - `true` -> Disable output interrupt when MBOX_FULL function is set.
  """
  @spec mailbox_full_mask?(bus_address) :: boolean
  def mailbox_full_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 5)

  @doc """
  MBOX_FULL_MSK

  - `false` -> Enable output interrupt when MBOX_FULL function is set.
  - `true` -> Disable output interrupt when MBOX_FULL function is set.
  """
  @spec mailbox_full_mask(bus_address, boolean) :: :ok | {:error, term}
  def mailbox_full_mask(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_mask, 5, value)

  @doc """
  MBOX_EMPTY_MSK

  - `false` -> Enable output interrupt when MBOX_EMPTY function is set.
  - `true` -> Disable output interrupt when MBOX_EMPTY function is set.
  """
  @spec mailbox_empty_mask?(bus_address) :: boolean
  def mailbox_empty_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 4)

  @doc """
  MBOX_EMPTY_MSK

  - `false` -> Enable output interrupt when MBOX_EMPTY function is set.
  - `true` -> Disable output interrupt when MBOX_EMPTY function is set.
  """
  @spec mailbox_empty_mask(bus_address, boolean) :: :ok | {:error, term}
  def mailbox_empty_mask(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_mask, 4, value)

  @doc """
  TEST_INT_MSK

  - `false` -> Enable output interrupt when TEST_INT function is set.
  - `true` -> Disable output interrupt when TEST_INT function is set.
  """
  @spec test_interrupt_mask?(bus_address) :: boolean
  def test_interrupt_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 3)

  @doc """
  TEST_INT_MSK

  - `false` -> Enable output interrupt when TEST_INT function is set.
  - `true` -> Disable output interrupt when TEST_INT function is set.
  """
  @spec test_interrupt_mask?(bus_address, boolean) :: :ok | {:error, term}
  def test_interrupt_mask?(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_mask, 3, value)

  @doc """
  LOCK_GRANT_MSK

  - `false` -> Enable output interrupt when LOCK_GRANT function is set.
  - `true` -> Disable output interrupt when LOCK_GRANT function is set.
  """
  @spec lock_grant_mask?(bus_address) :: boolean
  def lock_grant_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 2)

  @doc """
  LOCK_GRANT_MSK

  - `false` -> Enable output interrupt when LOCK_GRANT function is set.
  - `true` -> Disable output interrupt when LOCK_GRANT function is set.
  """
  @spec lock_grant_mask(bus_address, boolean) :: :ok | {:error, term}
  def lock_grant_mask(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_mask, 2, value)

  @doc """
  BUS_LOST_MSK

  - `false` -> Enable output interrupt when BUS_LOST function is set.
  - `true` -> Disable output interrupt when BUS_LOST function is set.
  """
  @spec bus_lost_mask?(bus_address) :: boolean
  def bus_lost_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 1)

  @doc """
  BUS_LOST_MSK

  - `false` -> Enable output interrupt when BUS_LOST function is set.
  - `true` -> Disable output interrupt when BUS_LOST function is set.
  """
  @spec bus_lost_mask(bus_address, boolean) :: :ok | {:error, term}
  def bus_lost_mask(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_mask, 1, value)

  @doc """
  INT_IN_MSK

  - `false` -> Enable output interrupt when INT_IN function is set.
  - `true` -> Disable output interrupt when INT_IN function is set.
  """
  @spec int_in_mask?(bus_address) :: boolean
  def int_in_mask?(bus_address), do: read_bit_as_boolean(bus_address, :interrupt_mask, 0)

  @doc """
  INT_IN_MSK

  - `false` -> Enable output interrupt when INT_IN function is set.
  - `true` -> Disable output interrupt when INT_IN function is set.
  """
  @spec int_in_mask(bus_address, boolean) :: :ok | {:error, term}
  def int_in_mask(bus_address, value),
    do: write_bit_as_boolean(bus_address, :interrupt_mask, 0, value)

  @doc """
  Read shared mailbox.
  """
  @spec read_mailbox(bus_address) :: {:ok, binary} | {:error, term}
  def read_mailbox(bus_address), do: Registers.mailbox(bus_address)

  @doc """
  Write shared mailbox.
  """
  @spec write_mailbox(bus_address, binary) :: :ok | {:error, term}
  def write_mailbox(bus_address, message), do: Registers.mailbox(bus_address, message)

  @doc """
  Request access to downstream bus.

  Requests access to the downstream bus and blocks until given access.
  """
  @spec request_downstream_bus(bus_address) :: :ok | {:error, term}
  def request_downstream_bus(bus_address), do: request_downstream_bus(bus_address, 0)

  @doc """
  Request access to downstream bus.

  Requests access to the downstream bus and blocks until given access.
  """
  @spec request_downstream_bus(bus_address, non_neg_integer) :: :ok | {:error, term}
  def request_downstream_bus(bus_address, reserve_time)
      when is_integer(reserve_time) and reserve_time >= 0 and reserve_time <= 0xFF do
    with :ok <- Registers.reserve_time(bus_address, reserve_time),
         # Request the bus lock.
         :ok <- Registers.control(bus_address, 0x1),
         :ok <- block_until_lock_granted(bus_address),
         # Connect the downstream bus.
         :ok <- Registers.control(bus_address, 0x5),
         true <- bus_connect?(bus_address) do
      :ok
    end
  end

  @doc """
  Abandon access to the downstream bus.
  """
  @spec abandon_downstream_bus(bus_address) :: :ok | {:error, term}
  def abandon_downstream_bus(bus_address), do: Registers.control(bus_address, 0)

  defp block_until_lock_granted(bus_address) do
    if lock_grant?(bus_address) do
      :ok
    else
      :timer.sleep(5)
      block_until_lock_granted(bus_address)
    end
  end

  defp read_bit_as_boolean(bus_address, register, bit)
       when is_atom(register) and is_integer(bit) and bit >= 0 and bit < 8 do
    value =
      Registers
      |> apply(register, [bus_address])
      |> get_bit(bit)

    value == 1
  end

  defp write_bit_as_boolean(bus_address, register, bit, true)
       when is_atom(register) and is_integer(bit) and bit >= 0 and bit < 8 do
    value =
      Registers
      |> apply(register, [bus_address])
      |> set_bit(bit)

    apply(Registers, register, [bus_address, value])
  end

  defp write_bit_as_boolean(bus_address, register, bit, false)
       when is_atom(register) and is_integer(bit) and bit >= 0 and bit < 8 do
    value =
      Registers
      |> apply(register, [bus_address])
      |> clear_bit(bit)

    apply(Registers, register, [bus_address, value])
  end

  defp get_bit(<<byte>>, bit), do: byte >>> bit &&& 1
  defp set_bit(byte, bit), do: set_bit(byte, bit, 1)
  defp set_bit(<<byte>>, bit, 1), do: byte ||| 1 <<< bit
  defp set_bit(byte, bit, 0), do: clear_bit(byte, bit)
  defp clear_bit(<<byte>>, bit), do: byte ||| ~~~(1 <<< bit)
end
