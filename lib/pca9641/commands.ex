defmodule PCA9641.Commands do
  alias PCA9641.Registers
  alias ElixirALE.I2C
  use Bitwise

  @moduledoc """
  Wrapper around the `Registers` module to handle sending commands to and from
  the device.
  """

  @type interrupt_reason ::
          :bus_hung | :mbox_full | :mbox_empty | :test_int | :lock_grant | :bus_lost | :int_in

  @doc false
  def start_link(bus, address), do: I2C.start_link(bus, address)

  @doc false
  def release(pid), do: I2C.release(pid)

  @doc """
  Retrieve the device ID.  For PCA9641 this should be 0x38.
  """
  @spec id(pid) :: {:ok, non_neg_integer} | {:error, term}
  def id(pid) do
    <<id>> = Registers.id(pid)
    {:ok, id}
  end

  @doc """
  PRIORITY

  Master can set this register bit for setting priority of the winner when two
  masters request the downstream bus at the same time.
  """
  @spec priority?(pid) :: boolean
  def priority?(pid), do: read_bit_as_boolean(pid, :control, 7)

  @doc """
  PRIORITY

  Master can set this register bit for setting priority of the winner when two
  masters request the downstream bus at the same time.
  """
  @spec priority(pid, boolean) :: :ok | {:error, term}
  def priority(pid, value), do: write_bit_as_boolean(pid, :control, 7, value)

  @doc """
  SMBUS_DIS

  When PCA9641 detects an SMBus time-out, if this bit is set, PCA9641 will
  disconnect I2C-bus from master to downstream bus.

  - `false` -> Normal operation.
  - `true` -> Connectivity between master and downstream bus will be
    disconnected upon detecting an SMBus time-out condition.
  """
  @spec downstream_disconnect_on_timeout?(pid) :: boolean
  def downstream_disconnect_on_timeout?(pid), do: read_bit_as_boolean(pid, :control, 6)

  @doc """
  SMBUS_DIS

  When PCA9641 detects an SMBus time-out, if this bit is set, PCA9641 will
  disconnect I2C-bus from master to downstream bus.

  - `false` -> Normal operation.
  - `true` -> Connectivity between master and downstream bus will be
    disconnected upon detecting an SMBus time-out condition.
  """
  @spec downstream_disconnect_on_timeout(pid, boolean) :: :ok | {:error, term}
  def downstream_disconnect_on_timeout(pid, value),
    do: write_bit_as_boolean(pid, :control, 6, value)

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
  @spec idle_timer_disconnect?(pid) :: boolean
  def idle_timer_disconnect?(pid), do: read_bit_as_boolean(pid, :control, 5)

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
  @spec idle_timer_disconnect(pid, boolean) :: :ok | {:error, term}
  def idle_timer_disconnect(pid, value), do: write_bit_as_boolean(pid, :control, 5, value)

  @doc """
  SMBUS_SWRST

  Non-granted or granted master sends a soft reset, if this bit is set, PCA9641
  sets clock LOW for 35 ms following reset of all register values to defaults.

  - `false` -> Normal operation.
  - `true` -> Enable sending SMBus time-out to downstream bus, after receiving a
    general call soft reset from master.
  """
  @spec smbus_software_reset?(pid) :: boolean
  def smbus_software_reset?(pid), do: read_bit_as_boolean(pid, :control, 4)

  @doc """
  SMBUS_SWRST

  Non-granted or granted master sends a soft reset, if this bit is set, PCA9641
  sets clock LOW for 35 ms following reset of all register values to defaults.

  - `false` -> Normal operation.
  - `true` -> Enable sending SMBus time-out to downstream bus, after receiving a
    general call soft reset from master.
  """
  @spec smbus_software_reset(pid, boolean) :: :ok | {:error, term}
  def smbus_software_reset(pid, value), do: write_bit_as_boolean(pid, :control, 4, value)

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
  @spec bus_init?(pid) :: boolean
  def bus_init?(pid), do: read_bit_as_boolean(pid, :control, 3)

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
  @spec bus_init(pid, boolean) :: :ok | {:error, term}
  def bus_init(pid, value), do: write_bit_as_boolean(pid, :control, 3, value)

  @doc """
  BUS_CONNECT

  Connectivity between master and downstream bus; the internal switch connects
  I2C-bus from master to downstream bus only if LOCK_GRANT = 1.

  - `false` -> Do not connect I2C-bus from master to downstream bus.
  - `true` -> Connect downstream bus; the internal switch is closed only if LOCK_GRANT = 1.
  """
  @spec bus_connect?(pid) :: boolean
  def bus_connect?(pid), do: read_bit_as_boolean(pid, :control, 2)

  @doc """
  BUS_CONNECT

  Connectivity between master and downstream bus; the internal switch connects
  I2C-bus from master to downstream bus only if LOCK_GRANT = 1.

  - `false` -> Do not connect I2C-bus from master to downstream bus.
  - `true` -> Connect downstream bus; the internal switch is closed only if LOCK_GRANT = 1.
  """
  @spec bus_connect(pid, boolean) :: :ok | {:error, term}
  def bus_connect(pid, value), do: write_bit_as_boolean(pid, :control, 2, value)

  @doc """
  LOCK_GRANT

  This is a status read only register bit. Lock grant status register bit
  indicates the ownership between reading master and the downstream bus. If this
  register bit is 1, the reading master has owned the downstream bus. If this
  register bit is zero, the reading master has not owned the downstream bus.

  - `false` -> This master does not have a lock on the downstream bus.
  - `true` -> This master has a lock on the downstream bus.
  """
  @spec lock_grant?(pid) :: boolean
  def lock_grant?(pid), do: read_bit_as_boolean(pid, :control, 1)

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
  @spec lock_request?(pid) :: boolean
  def lock_request?(pid), do: read_bit_as_boolean(pid, :control, 0)

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
  @spec lock_request(pid, boolean) :: :ok | {:error, term}
  def lock_request(pid, value), do: write_bit_as_boolean(pid, :control, 0, value)

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
  @spec sda_becomes_io?(pid) :: boolean
  def sda_becomes_io?(pid), do: read_bit_as_boolean(pid, :status, 7)

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
  @spec sda_becomes_io(pid, boolean) :: :ok | {:error, term}
  def sda_becomes_io(pid, value), do: write_bit_as_boolean(pid, :status, 7, value)

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
  @spec scl_becomes_io?(pid) :: boolean
  def scl_becomes_io?(pid), do: read_bit_as_boolean(pid, :status, 6)

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
  @spec scl_becomes_io(pid, boolean) :: :ok | {:error, term}
  def scl_becomes_io(pid, value), do: write_bit_as_boolean(pid, :status, 6, value)

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
  @spec test_interrupt_pin(pid, boolean) :: :ok | {:error, term}
  def test_interrupt_pin(pid, value), do: write_bit_as_boolean(pid, :status, 5, value)

  @doc """
  MBOX_FULL

  This is a read-only status register bit. If this bit is ‘0’, it indicates no
  data is available in the mail box. If it is ‘1’, it indicates new data is
  available in the mail box.

  - `false` -> No data is available for *this* master.
  - `true` -> Mailbox contains data for *this* master from the other master.
  """
  @spec mailbox_full?(pid) :: boolean
  def mailbox_full?(pid), do: read_bit_as_boolean(pid, :status, 4)

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
  @spec mailbox_empty?(pid) :: boolean
  def mailbox_empty?(pid), do: read_bit_as_boolean(pid, :status, 3)

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
  @spec bus_hung?(pid) :: boolean
  def bus_hung?(pid), do: read_bit_as_boolean(pid, :status, 2)

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
  @spec bus_initialisation_failed?(pid) :: boolean
  def bus_initialisation_failed?(pid), do: read_bit_as_boolean(pid, :status, 1)

  @doc """
  OTHER_LOCK

  This is a status read-only register bit. Other master lock status indicates
  the ownership between other master and the downstream bus. If this register
  bit is ‘1’, the other master has owned the downstream bus. If this register
  bit is ‘0’, the other master does not own the downstream bus.

  - `false` -> The other master does not have a lock on the downstream bus.
  - `true` -> The other master has a lock on the downstream bus.
  """
  @spec other_lock?(pid) :: boolean
  def other_lock?(pid), do: read_bit_as_boolean(pid, :status, 0)

  @doc """
  RES_TIME

  Reserve timer. Changes during LOCK_GRANT = 1 will have no effect.

  Returns `{:ok, n}` where `n` is the number if milliseconds remaining in the
  reservation.
  """
  @spec reserve_time(pid) :: {:ok, non_neg_integer} | {:error, term}
  def reserve_time(pid) do
    <<ms>> = Registers.reserve_time(pid)
    {:ok, ms}
  end

  @doc """
  RES_TIME

  Reserve timer. Changes during LOCK_GRANT = 1 will have no effect.

  `ms` is the number of milliseconds remaining in the reservation.
  """
  @spec reserve_time(pid) :: {:ok, non_neg_integer} | {:error, term}
  def reserve_time(pid, ms) when is_integer(ms) and ms >= 0 and ms <= 0xFF,
    do: Registers.reserve_time(pid, ms)

  def reserve_time(_pid, _ms), do: {:error, "Invalid milliseconds value"}

  @doc """
  Indicates the reasons for which an interrupt was generated (if any).
  """
  @spec interrupt_reason(pid) :: [interrupt_reason()]
  def interrupt_reason(pid) do
    value = Registers.interrupt_status(pid)

    %{
      bus_hung: 6,
      mbox_full: 5,
      mbox_empty: 4,
      test_int: 3,
      lock_grant: 2,
      bus_lost: 1,
      int_in: 0
    }
    |> Enum.reduce([], fn {name, idx}, interrupts ->
      if get_bit(value, idx) == 1,
        do: [name | interrupts],
        else: interrupts
    end)
  end

  @doc """
  BUS_HUNG_INT

  Indicates to both masters that SDA signal is LOW and SCL signal does not
  toggle for more than 500 ms or SCL is LOW for 500 ms.

  - `false` -> No interrupt generated; normal operation.
  - `true` -> Interrupt generated; downstream bus cannot recover; when SDA
    signal is LOW and SCL signal does not toggle for more than 500 ms or SCL is
    LOW for 500 ms,
  """
  @spec bus_hung_interrupt?(pid) :: boolean
  def bus_hung_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 6)

  @doc """
  BUS_HUNG_INT

  Indicates to both masters that SDA signal is LOW and SCL signal does not
  toggle for more than 500 ms or SCL is LOW for 500 ms.

  - `false` -> No interrupt generated; normal operation.
  - `true` -> Interrupt generated; downstream bus cannot recover; when SDA
    signal is LOW and SCL signal does not toggle for more than 500 ms or SCL is
    LOW for 500 ms,
  """
  @spec bus_hung_interrupt(pid, boolean) :: :ok | {:error, term}
  def bus_hung_interrupt(pid, value), do: write_bit_as_boolean(pid, :interrupt_status, 6, value)

  @doc """
  MBOX_FULL_INT

  Indicates the mailbox has new mail.

  - `false` -> No interrupt generated; mailbox is not full.
  - `true` -> Interrupt generated; mailbox full.
  """
  @spec mailbox_full_interrupt?(pid) :: boolean
  def mailbox_full_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 5)

  @doc """
  MBOX_FULL_INT

  Indicates the mailbox has new mail.

  - `false` -> No interrupt generated; mailbox is not full.
  - `true` -> Interrupt generated; mailbox full.
  """
  @spec mailbox_full_interrupt(pid, boolean) :: :ok | {:error, term}
  def mailbox_full_interrupt(pid, value),
    do: write_bit_as_boolean(pid, :interrupt_status, 5, value)

  @doc """
  MBOX_EMPTY_INT

  Indicates the sent mail is empty, other master has read the mail.

  - `false` -> No interrupt generated; sent mail is not empty.
  - `true` -> Interrupt generated; mailbox is empty.
  """
  @spec mailbox_empty_interrupt?(pid) :: boolean
  def mailbox_empty_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 4)

  @doc """
  MBOX_EMPTY_INT

  Indicates the sent mail is empty, other master has read the mail.

  - `false` -> No interrupt generated; sent mail is not empty.
  - `true` -> Interrupt generated; mailbox is empty.
  """
  @spec mailbox_empty_interrupt(pid, boolean) :: :ok | {:error, term}
  def mailbox_empty_interrupt(pid, value),
    do: write_bit_as_boolean(pid, :interrupt_status, 4, value)

  @doc """
  TEST_INT_INT

  Indicates this master has sent an interrupt to itself.

  - `false` -> No interrupt generated; master has not set the TEST_INT bit in
    STATUS register.
  - `true` -> Interrupt generated; master activates its interrupt pin via the
    TEST_INT bit in STATUS register.
  """
  @spec test_interrupt_pin_interrupt?(pid) :: boolean
  def test_interrupt_pin_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 3)

  @doc """
  TEST_INT_INT

  Indicates this master has sent an interrupt to itself.

  - `false` -> No interrupt generated; master has not set the TEST_INT bit in
    STATUS register.
  - `true` -> Interrupt generated; master activates its interrupt pin via the
    TEST_INT bit in STATUS register.
  """
  @spec test_interrupt_pin_interrupt(pid, true) :: :ok | {:error, term}
  def test_interrupt_pin_interrupt(pid, value),
    do: write_bit_as_boolean(pid, :interrupt_status, 2, value)

  @doc """
  LOCK_GRANT_INT

  Indicates the master has a lock (ownership) on the downstream bus.

  - `false` -> No interrupt generated; this master does not have a lock on the
    downstream bus.
  - `true` -> Interrupt generated; this master has a lock on the downstream bus.
  """
  @spec lock_grant_interrupt?(pid) :: boolean
  def lock_grant_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 2)

  @doc """
  LOCK_GRANT_INT

  Indicates the master has a lock (ownership) on the downstream bus.

  - `false` -> No interrupt generated; this master does not have a lock on the
    downstream bus.
  - `true` -> Interrupt generated; this master has a lock on the downstream bus.
  """
  @spec lock_grant_interrupt(pid, boolean) :: :ok | {:error, term}
  def lock_grant_interrupt(pid, value), do: write_bit_as_boolean(pid, :interrupt_status, 2, value)

  @doc """
  BUS_LOST_INT

  Indicates the master has involuntarily lost the ownership of the downstream
  bus.

  - `false` -> No interrupt generated; this master is controlling the downstream
    bus.
  - `true` -> Interrupt generated; this master has involuntarily lost the
    control of the downstream bus.
  """
  @spec bus_lost_interrupt?(pid) :: boolean
  def bus_lost_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 1)

  @doc """
  BUS_LOST_INT

  Indicates the master has involuntarily lost the ownership of the downstream
  bus.

  - `false` -> No interrupt generated; this master is controlling the downstream
    bus.
  - `true` -> Interrupt generated; this master has involuntarily lost the
    control of the downstream bus.
  """
  @spec bus_lost_interrupt(pid, boolean) :: :ok | {:error, term}
  def bus_lost_interrupt(pid, value), do: write_bit_as_boolean(pid, :interrupt_status, 1, value)

  @doc """
  INT_IN_INT

  Indicates that there is an interrupt from the downstream bus to both the
  granted and non-granted masters.

  - `false` -> No interrupt on interrupt input pin INT_IN.
  - `true` -> Interrupt on interrupt input pin INT_IN.
  """
  @spec interupt_in_interrupt?(pid) :: boolean
  def interupt_in_interrupt?(pid), do: read_bit_as_boolean(pid, :interrupt_status, 0)

  @doc """
  INT_IN_INT

  Indicates that there is an interrupt from the downstream bus to both the
  granted and non-granted masters.

  - `false` -> No interrupt on interrupt input pin INT_IN.
  - `true` -> Interrupt on interrupt input pin INT_IN.
  """
  @spec interupt_in_interrupt(pid, boolean) :: :ok | {:error, term}
  def interupt_in_interrupt(pid, value),
    do: write_bit_as_boolean(pid, :interrupt_status, 0, value)

  @doc """
  BUS_HUNG_MSK

  - `false` -> Enable output interrupt when BUS_HUNG function is set.
  - `true` -> Disable output interrupt when BUS_HUNG function is set.
  """
  @spec bus_hung_mask?(pid) :: boolean
  def bus_hung_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 6)

  @doc """
  MBOX_FULL_MSK

  - `false` -> Enable output interrupt when MBOX_FULL function is set.
  - `true` -> Disable output interrupt when MBOX_FULL function is set.
  """
  @spec mailbox_full_mask?(pid) :: boolean
  def mailbox_full_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 5)

  @doc """
  MBOX_FULL_MSK

  - `false` -> Enable output interrupt when MBOX_FULL function is set.
  - `true` -> Disable output interrupt when MBOX_FULL function is set.
  """
  @spec mailbox_full_mask(pid, boolean) :: :ok | {:error, term}
  def mailbox_full_mask(pid, value), do: write_bit_as_boolean(pid, :interrupt_mask, 5, value)

  @doc """
  MBOX_EMPTY_MSK

  - `false` -> Enable output interrupt when MBOX_EMPTY function is set.
  - `true` -> Disable output interrupt when MBOX_EMPTY function is set.
  """
  @spec mailbox_empty_mask?(pid) :: boolean
  def mailbox_empty_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 4)

  @doc """
  MBOX_EMPTY_MSK

  - `false` -> Enable output interrupt when MBOX_EMPTY function is set.
  - `true` -> Disable output interrupt when MBOX_EMPTY function is set.
  """
  @spec mailbox_empty_mask(pid, boolean) :: :ok | {:error, term}
  def mailbox_empty_mask(pid, value), do: write_bit_as_boolean(pid, :interrupt_mask, 4, value)

  @doc """
  TEST_INT_MSK

  - `false` -> Enable output interrupt when TEST_INT function is set.
  - `true` -> Disable output interrupt when TEST_INT function is set.
  """
  @spec test_interrupt_mask?(pid) :: boolean
  def test_interrupt_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 3)

  @doc """
  TEST_INT_MSK

  - `false` -> Enable output interrupt when TEST_INT function is set.
  - `true` -> Disable output interrupt when TEST_INT function is set.
  """
  @spec test_interrupt_mask?(pid, boolean) :: :ok | {:error, term}
  def test_interrupt_mask?(pid, value), do: write_bit_as_boolean(pid, :interrupt_mask, 3, value)

  @doc """
  LOCK_GRANT_MSK

  - `false` -> Enable output interrupt when LOCK_GRANT function is set.
  - `true` -> Disable output interrupt when LOCK_GRANT function is set.
  """
  @spec lock_grant_mask?(pid) :: boolean
  def lock_grant_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 2)

  @doc """
  LOCK_GRANT_MSK

  - `false` -> Enable output interrupt when LOCK_GRANT function is set.
  - `true` -> Disable output interrupt when LOCK_GRANT function is set.
  """
  @spec lock_grant_mask(pid, boolean) :: :ok | {:error, term}
  def lock_grant_mask(pid, value), do: write_bit_as_boolean(pid, :interrupt_mask, 2, value)

  @doc """
  BUS_LOST_MSK

  - `false` -> Enable output interrupt when BUS_LOST function is set.
  - `true` -> Disable output interrupt when BUS_LOST function is set.
  """
  @spec bus_lost_mask?(pid) :: boolean
  def bus_lost_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 1)

  @doc """
  BUS_LOST_MSK

  - `false` -> Enable output interrupt when BUS_LOST function is set.
  - `true` -> Disable output interrupt when BUS_LOST function is set.
  """
  @spec bus_lost_mask(pid, boolean) :: :ok | {:error, term}
  def bus_lost_mask(pid, value), do: write_bit_as_boolean(pid, :interrupt_mask, 1, value)

  @doc """
  INT_IN_MSK

  - `false` -> Enable output interrupt when INT_IN function is set.
  - `true` -> Disable output interrupt when INT_IN function is set.
  """
  @spec int_in_mask?(pid) :: boolean
  def int_in_mask?(pid), do: read_bit_as_boolean(pid, :interrupt_mask, 0)

  @doc """
  INT_IN_MSK

  - `false` -> Enable output interrupt when INT_IN function is set.
  - `true` -> Disable output interrupt when INT_IN function is set.
  """
  @spec int_in_mask(pid, boolean) :: :ok | {:error, term}
  def int_in_mask(pid, value), do: write_bit_as_boolean(pid, :interrupt_mask, 0, value)

  @doc """
  Read shared mailbox.
  """
  @spec read_mailbox(pid) :: {:ok, binary} | {:error, term}
  def read_mailbox(pid), do: Registers.mailbox(pid)

  @doc """
  Write shared mailbox.
  """
  @spec write_mailbox(pid, binary) :: :ok | {:error, term}
  def write_mailbox(pid, message), do: Registers.mailbox(pid, message)

  @doc """
  Request access to downstream bus.

  Requests access to the downstream bus and blocks until given access.
  """
  @spec request_downstream_bus(pid) :: :ok | {:error, term}
  def request_downstream_bus(pid), do: request_downstream_bus(pid, 0)

  @doc """
  Request access to downstream bus.

  Requests access to the downstream bus and blocks until given access.
  """
  @spec request_downstream_bus(pid, non_neg_integer) :: :ok | {:error, term}
  def request_downstream_bus(pid, reserve_time)
      when is_integer(reserve_time) and reserve_time >= 0 and reserve_time <= 0xFF do
    with :ok <- Registers.reserve_time(pid, reserve_time),
         # Request the bus lock.
         :ok <- Registers.control(pid, 0x1),
         :ok <- block_until_lock_granted(pid),
         # Connect the downstream bus.
         :ok <- Registers.control(pid, 0x5),
         true <- bus_connect?(pid) do
      :ok
    end
  end

  @doc """
  Abandon access to the downstream bus.
  """
  @spec abandon_downstream_bus(pid) :: :ok | {:error, term}
  def abandon_downstream_bus(pid), do: Registers.control(pid, 0)

  defp block_until_lock_granted(pid) do
    if lock_grant?(pid) do
      :ok
    else
      :timer.sleep(5)
      block_until_lock_granted(pid)
    end
  end

  defp read_bit_as_boolean(pid, register, bit)
       when is_pid(pid) and is_atom(register) and is_integer(bit) and bit >= 0 and bit < 8 do
    value =
      Registers
      |> apply(register, [pid])
      |> get_bit(bit)

    value == 1
  end

  defp write_bit_as_boolean(pid, register, bit, true)
       when is_pid(pid) and is_atom(register) and is_integer(bit) and bit >= 0 and bit < 8 do
    value =
      Registers
      |> apply(register, [pid])
      |> set_bit(bit)

    apply(Registers, register, [pid, value])
  end

  defp write_bit_as_boolean(pid, register, bit, false)
       when is_pid(pid) and is_atom(register) and is_integer(bit) and bit >= 0 and bit < 8 do
    value =
      Registers
      |> apply(register, [pid])
      |> clear_bit(bit)

    apply(Registers, register, [pid, value])
  end

  defp get_bit(<<byte>>, bit), do: byte >>> bit &&& 1
  defp set_bit(byte, bit), do: set_bit(byte, bit, 1)
  defp set_bit(<<byte>>, bit, 1), do: byte ||| 1 <<< bit
  defp set_bit(byte, bit, 0), do: clear_bit(byte, bit)
  defp clear_bit(<<byte>>, bit), do: byte ||| ~~~(1 <<< bit)
end
