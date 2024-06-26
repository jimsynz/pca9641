defmodule PCA9641 do
  @derive [Wafer.Chip]
  defstruct ~w[conn int_pin state]a
  @behaviour Wafer.Conn
  alias PCA9641.Registers
  alias Wafer.Conn
  import Wafer.Twiddles
  require Logger

  @moduledoc """
  PCA9641 Driver for Elixir using Wafer.

  The PCA9641 I2C bus arbiter allows two I2C masters (eg Raspberry Pis) to be
  connected to the same downstream I2C bus.  The chip decides which master has
  access to the bus based on it's own internal state machine.

  The device also contains an interrupt input pin which can be used for
  downstream devices to signal interrupts and be passed to the two interrupt
  outputs connected to the two masters.

  ##  Examples

  Connecting to the device using Elixir Circuits.

    iex> {:ok, i2c_conn} = Wafer.Driver.Circuits.I2C.acquire(bus_name: "i2c-1", address: 0x70)
    ...> {:ok, int_conn} = Wafer.Driver.Circuits.GPIO.acquire(pin: 7, direction: :in)
    ...> {:ok, conn} = PCA9641.acquire(conn: i2c_conn, int_pin: int_conn)


  """

  @interrupts_fwd %{
    bus_hung: 6,
    mbox_full: 5,
    mbox_empty: 4,
    test_int: 3,
    lock_grant: 2,
    bus_lost: 1,
    int_in: 0
  }
  @interrupts_bkwd @interrupts_fwd |> Enum.map(fn {k, v} -> {v, k} end) |> Enum.into(%{})

  @type interrupt_name ::
          :bus_hung | :mbox_full | :mbox_empty | :test_int | :lock_grant | :bus_lost | :int_in

  @type t :: %PCA9641{conn: Conn.t(), int_pin: Conn.t()}
  @type mailbox_data :: <<_::16>>
  @type acquire_options :: [acquire_option]
  @type acquire_option :: {:conn, Conn.t(), int_pin: Conn.t()}

  # The magic number that means this is really a PCA9641 device.
  @pca9641_id 0x38

  @doc """
  Acquire a connection to the PCA9641 device using the passed in I2C connection.

  ## Options:
    - `conn` (required) an I2C connection, probably from `ElixirALE.I2C` or
      `Circuits.I2C`.
    - `int_pin` a (optional) GPIO connection for the interrupt pin  This should
      be already set to direction `:in`.
  """
  @spec acquire(acquire_options) :: {:ok, t} | {:error, reason :: any}
  @impl Wafer.Conn
  def acquire(options) do
    with {:ok, conn} <- Keyword.fetch(options, :conn),
         int_pin <- Keyword.get(options, :int_pin) do
      {:ok, %PCA9641{conn: conn, int_pin: int_pin, state: :unknown}}
    else
      :error -> {:error, "`PCA9641.acquire/1` requires the `conn` option."}
    end
  end

  @doc """
  Enable interrupts on the `int_pin`.

  Enables interrupts on the GPIO pin which is connected to the PCA9641 interrupt
  pin.  The Wafer interrupt message metadata field will contain this PCA9641
  conn.
  """
  @spec interrupt_pin_enable(t) :: {:ok, t} | {:error, reason :: any}
  def interrupt_pin_enable(%PCA9641{int_pin: nil}), do: {:error, "No interrupt pin specified."}

  def interrupt_pin_enable(%PCA9641{int_pin: conn} = dev) do
    with {:ok, conn} <- Wafer.GPIO.enable_interrupt(conn, :falling, dev),
         do: {:ok, %{dev | int_pin: conn}}
  end

  @doc """
  Enable interrupts on the `int_pin`.

  Enables interrupts on the GPIO pin which is connected to the PCA9641 interrupt
  pin.  The Wafer interrupt message metadata field will contain a two-tuple of
  this PCA9641 conn and `metadata`.
  """
  @spec interrupt_pin_enable(t, metadata :: any) :: {:ok, t} | {:error, reason :: any}
  def interrupt_pin_enable(%PCA9641{int_pin: nil}, _metadata),
    do: {:error, "No interrupt pin specified."}

  def interrupt_pin_enable(%PCA9641{int_pin: conn} = dev, metadata) do
    with {:ok, conn} <- Wafer.GPIO.enable_interrupt(conn, :falling, {dev, metadata}),
         do: {:ok, %{dev | int_pin: conn}}
  end

  @doc """
  Disable interrupts on the `int_pin`.

  Disables interrupts on the GPIO pin which is connected to the PCA9641
  interrupt pin.
  """
  @spec interrupt_pin_disable(t) :: {:ok, t} | {:error, reason :: any}
  def interrupt_pin_disable(%PCA9641{int_pin: nil}), do: {:error, "No interrupt pin specified."}

  def interrupt_pin_disable(%PCA9641{int_pin: conn} = dev) do
    with {:ok, conn} <- Wafer.GPIO.disable_interrupt(conn, :both),
         do: {:ok, %{dev | int_pin: conn}}
  end

  @doc """
  Verify the contents of the identity register.

  It should match the expected value of `#{@pca9641_id}`.
  """
  @spec verify_identity(t) :: {:ok, t} | {:error, reason :: any}
  def verify_identity(%PCA9641{conn: conn} = dev) do
    case Registers.read_id(conn) do
      {:ok, <<@pca9641_id>>} -> {:ok, %{dev | conn: conn}}
      {:ok, <<id>>} -> {:error, "Found incorrect ID #{inspect(id)}"}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Attempt to acquire the downstream I2C bus.
  """
  @spec request_downstream_bus(t) :: {:ok, t} | {:error, reason :: any}
  def request_downstream_bus(%PCA9641{} = dev) do
    case lock_request(dev, true) do
      {:ok, dev} -> wait_for_bus_init(dev)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  PRIORITY

  Master can set this register bit for setting priority of the winner when two
  masters request the downstream bus at the same time.
  """
  @spec priority?(t) :: boolean
  def priority?(conn) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 7),
         do: true,
         else: (_ -> false)
  end

  @doc """
  PRIORITY

  Master can set this register bit for setting priority of the winner when two
  masters request the downstream bus at the same time.
  """
  @spec priority(t, boolean) :: {:ok, t} | {:error, reason :: any}
  def priority(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 7)),
         do: {:ok, %{dev | conn: conn}}
  end

  def priority(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 7)),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  SMBUS_DIS

  When PCA9641 detects an SMBus time-out, if this bit is set, PCA9641 will
  disconnect I2C-bus from master to downstream bus.

  - `false` -> Normal operation.
  - `true` -> Connectivity between master and downstream bus will be
    disconnected upon detecting an SMBus time-out condition.
  """
  @spec downstream_disconnect_on_timeout?(t) :: boolean
  def downstream_disconnect_on_timeout?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 6),
         do: true,
         else: (_ -> false)
  end

  @doc """
  SMBUS_DIS

  When PCA9641 detects an SMBus time-out, if this bit is set, PCA9641 will
  disconnect I2C-bus from master to downstream bus.

  - `false` -> Normal operation.
  - `true` -> Connectivity between master and downstream bus will be
    disconnected upon detecting an SMBus time-out condition.
  """
  @spec downstream_disconnect_on_timeout(t, boolean) :: {:ok, t} | {:error, term}
  def downstream_disconnect_on_timeout(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 6)),
         do: {:ok, %{dev | conn: conn}}
  end

  def downstream_disconnect_on_timeout(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 6)),
         do: {:ok, %{dev | conn: conn}}
  end

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
  @spec idle_timer_disconnect?(t) :: boolean
  def idle_timer_disconnect?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 5),
         do: true,
         else: (_ -> false)
  end

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
  @spec idle_timer_disconnect(t, boolean) :: {:ok, t} | {:error, term}
  def idle_timer_disconnect(%{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 5)),
         do: {:ok, %{dev | conn: conn}}
  end

  def idle_timer_disconnect(%{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 5)),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  SMBUS_SWRST

  Non-granted or granted master sends a soft reset, if this bit is set, PCA9641
  sets clock LOW for 35 ms following reset of all register values to defaults.

  - `false` -> Normal operation.
  - `true` -> Enable sending SMBus time-out to downstream bus, after receiving a
    general call soft reset from master.
  """
  @spec smbus_software_reset?(t) :: boolean
  def smbus_software_reset?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 4),
         do: true,
         else: (_ -> false)
  end

  @doc """
  SMBUS_SWRST

  Non-granted or granted master sends a soft reset, if this bit is set, PCA9641
  sets clock LOW for 35 ms following reset of all register values to defaults.

  - `false` -> Normal operation.
  - `true` -> Enable sending SMBus time-out to downstream bus, after receiving a
    general call soft reset from master.
  """
  @spec smbus_software_reset(t, boolean) :: {:ok, t} | {:error, term}
  def smbus_software_reset(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 4)),
         do: {:ok, %{dev | conn: conn}}
  end

  def smbus_software_reset(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 4)),
         do: {:ok, %{dev | conn: conn}}
  end

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
  @spec bus_init?(t) :: boolean
  def bus_init?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 3),
         do: true,
         else: (_ -> false)
  end

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
  @spec bus_init(t, boolean) :: {:ok, t} | {:error, term}
  def bus_init(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 3)),
         do: {:ok, %{dev | conn: conn}}
  end

  def bus_init(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 3)),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  BUS_CONNECT

  Connectivity between master and downstream bus; the internal switch connects
  I2C-bus from master to downstream bus only if LOCK_GRANT = 1.

  - `false` -> Do not connect I2C-bus from master to downstream bus.
  - `true` -> Connect downstream bus; the internal switch is closed only if LOCK_GRANT = 1.
  """
  @spec bus_connect?(t) :: boolean
  def bus_connect?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 2),
         do: true,
         else: (_ -> false)
  end

  @doc """
  BUS_CONNECT

  Connectivity between master and downstream bus; the internal switch connects
  I2C-bus from master to downstream bus only if LOCK_GRANT = 1.

  - `false` -> Do not connect I2C-bus from master to downstream bus.
  - `true` -> Connect downstream bus; the internal switch is closed only if LOCK_GRANT = 1.
  """
  @spec bus_connect(t, boolean) :: {:ok, t} | {:error, term}
  def bus_connect(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 2)),
         do: {:ok, %{dev | conn: conn}}
  end

  def bus_connect(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 2)),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  LOCK_GRANT

  This is a status read only register bit. Lock grant status register bit
  indicates the ownership between reading master and the downstream bus. If this
  register bit is 1, the reading master has owned the downstream bus. If this
  register bit is zero, the reading master has not owned the downstream bus.

  - `false` -> This master does not have a lock on the downstream bus.
  - `true` -> This master has a lock on the downstream bus.
  """
  @spec lock_grant?(t) :: boolean
  def lock_grant?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 1),
         do: true,
         else: (_ -> false)
  end

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
  @spec lock_request?(t) :: boolean
  def lock_request?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_control(conn),
         true <- get_bool(data, 0),
         do: true,
         else: (_ -> false)
  end

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
  @spec lock_request(t, boolean) :: {:ok, t} | {:error, term}
  def lock_request(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_control(conn, &set_bit(&1, 0)),
         do: {:ok, %{dev | conn: conn}}
  end

  def lock_request(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_control(conn, &clear_bit(&1, 0)),
         do: {:ok, %{dev | conn: conn}}
  end

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
  @spec sda_becomes_io?(t) :: boolean
  def sda_becomes_io?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 7),
         do: true,
         else: (_ -> false)
  end

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
  @spec sda_becomes_io(t, boolean) :: {:ok, t} | {:error, term}
  def sda_becomes_io(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_status(conn, &set_bit(&1, 7)),
         do: {:ok, %{dev | conn: conn}}
  end

  def sda_becomes_io(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_status(conn, &clear_bit(&1, 7)),
         do: {:ok, %{dev | conn: conn}}
  end

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
  @spec scl_becomes_io?(t) :: boolean
  def scl_becomes_io?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 6),
         do: true,
         else: (_ -> false)
  end

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
  @spec scl_becomes_io(t, boolean) :: {:ok, t} | {:error, term}
  def scl_becomes_io(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_status(conn, &set_bit(&1, 6)),
         do: {:ok, %{dev | conn: conn}}
  end

  def scl_becomes_io(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_status(conn, &clear_bit(&1, 6)),
         do: {:ok, %{dev | conn: conn}}
  end

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
  @spec test_interrupt_pin?(t) :: boolean
  def test_interrupt_pin?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 5),
         do: true,
         else: (_ -> false)
  end

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
  @spec test_interrupt_pin(t, boolean) :: {:ok, t} | {:error, term}
  def test_interrupt_pin(%PCA9641{conn: conn} = dev, true) do
    with {:ok, conn} <- Registers.update_status(conn, &set_bit(&1, 5)),
         do: {:ok, %{dev | conn: conn}}
  end

  def test_interrupt_pin(%PCA9641{conn: conn} = dev, false) do
    with {:ok, conn} <- Registers.update_status(conn, &clear_bit(&1, 5)),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  MBOX_FULL

  This is a read-only status register bit. If this bit is ‘0’, it indicates no
  data is available in the mail box. If it is ‘1’, it indicates new data is
  available in the mail box.

  - `false` -> No data is available for *this* master.
  - `true` -> Mailbox contains data for *this* master from the other master.
  """
  @spec mailbox_full?(t) :: boolean
  def mailbox_full?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 4),
         do: true,
         else: (_ -> false)
  end

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
  @spec mailbox_empty?(t) :: boolean
  def mailbox_empty?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 3),
         do: true,
         else: (_ -> false)
  end

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
  @spec bus_hung?(t) :: boolean
  def bus_hung?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 2),
         do: true,
         else: (_ -> false)
  end

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
  @spec bus_initialisation_failed?(t) :: boolean
  def bus_initialisation_failed?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 1),
         do: true,
         else: (_ -> false)
  end

  @doc """
  OTHER_LOCK

  This is a status read-only register bit. Other master lock status indicates
  the ownership between other master and the downstream bus. If this register
  bit is ‘1’, the other master has owned the downstream bus. If this register
  bit is ‘0’, the other master does not own the downstream bus.

  - `false` -> The other master does not have a lock on the downstream bus.
  - `true` -> The other master has a lock on the downstream bus.
  """
  @spec other_lock?(t) :: boolean
  def other_lock?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_status(conn),
         true <- get_bool(data, 0),
         do: true,
         else: (_ -> false)
  end

  @doc """
  RES_TIME

  Reserve timer. Changes during LOCK_GRANT = 1 will have no effect.

  Returns `{:ok, n}` where `n` is the number if milliseconds remaining in the
  reservation.
  """
  @spec reserve_time(t) :: {:ok, non_neg_integer, t} | {:error, term}
  def reserve_time(%PCA9641{conn: conn} = dev) do
    with {:ok, <<ms>>} <- Registers.read_reserve_time(conn), do: {:ok, ms, dev}
  end

  @doc """
  RES_TIME

  Reserve timer. Changes during LOCK_GRANT = 1 will have no effect.

  `ms` is the number of milliseconds remaining in the reservation.
  """
  @spec reserve_time(t) :: {:ok, t} | {:error, term}
  def reserve_time(%PCA9641{conn: conn} = dev, ms)
      when is_integer(ms) and ms >= 0 and ms <= 0xFF do
    with {:ok, conn} <- Registers.write_reserve_time(conn, <<ms>>), do: {:ok, %{dev | conn: conn}}
  end

  def reserve_time(_conn, _ms), do: {:error, "Invalid milliseconds value"}

  @doc """
  Indicates the reasons for which an interrupt was generated (if any).
  """
  @spec interrupt_reason(t) :: {:ok, [interrupt_name()]} | {:error, reason :: any}
  def interrupt_reason(%PCA9641{conn: conn}) do
    with {:ok, <<value>>} <- Registers.read_interrupt_status(conn) do
      reasons =
        @interrupts_fwd
        |> Enum.reduce([], fn {name, idx}, interrupts ->
          if get_bit(value, idx) == 1,
            do: [name | interrupts],
            else: interrupts
        end)

      {:ok, reasons}
    end
  end

  @doc """
  Clear specific interrupts from the interrupt status register
  """
  @spec interrupt_clear(t, :all | [interrupt_name()]) :: {:ok, t} | {:error, term}
  def interrupt_clear(%PCA9641{conn: conn} = dev, :all) do
    with {:ok, conn} <- Registers.write_interrupt_status(conn, <<0x7F>>),
         do: {:ok, %{dev | conn: conn}}
  end

  def interrupt_clear(%PCA9641{conn: conn} = dev, interrupt_names)
      when is_list(interrupt_names) do
    clear_mask =
      interrupt_names
      |> Enum.reduce(<<0>>, fn name, mask ->
        case Map.fetch(@interrupts_fwd, name) do
          {:ok, i} -> set_bit(mask, i)
          _ -> mask
        end
      end)

    with {:ok, conn} <- Registers.write_interrupt_status(conn, clear_mask),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  Enable the specified interrupts.
  """
  @spec interrupt_enable(t, :all | :none | [interrupt_name()]) :: {:ok, t} | {:error, term}
  def interrupt_enable(%PCA9641{conn: conn} = dev, :all) do
    with {:ok, conn} <- Registers.write_interrupt_mask(conn, <<0>>),
         do: {:ok, %{dev | conn: conn}}
  end

  def interrupt_enable(%PCA9641{conn: conn} = dev, :none) do
    with {:ok, conn} <- Registers.write_interrupt_mask(conn, <<0x7F>>),
         do: {:ok, %{dev | conn: conn}}
  end

  def interrupt_enable(%PCA9641{conn: conn} = dev, interrupts) do
    with {:ok, conn} <-
           Registers.update_interrupt_mask(conn, fn data ->
             interrupts
             |> Enum.reduce(data, fn interrupt_name, data ->
               bit = Map.fetch!(@interrupts_fwd, interrupt_name)
               clear_bit(data, bit)
             end)
           end),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  Returns a list of atoms containing the
  """
  @spec interrupt_enabled(t) :: {:ok, [interrupt_name()]} | {:error, term}
  def interrupt_enabled(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn) do
      interrupts =
        data
        |> find_zeroes()
        |> Enum.reduce([], fn i, interrupts ->
          case Map.fetch(@interrupts_bkwd, i) do
            {:ok, name} -> [name | interrupts]
            _ -> interrupts
          end
        end)

      {:ok, interrupts}
    end
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
  @spec bus_hung_interrupt?(t) :: boolean
  def bus_hung_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 6),
         do: true,
         else: (_ -> false)
  end

  @doc """
  MBOX_FULL_INT

  Indicates the mailbox has new mail.

  - `false` -> No interrupt generated; mailbox is not full.
  - `true` -> Interrupt generated; mailbox full.
  """
  @spec mailbox_full_interrupt?(t) :: boolean
  def mailbox_full_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 5),
         do: true,
         else: (_ -> false)
  end

  @doc """
  MBOX_EMPTY_INT

  Indicates the sent mail is empty, other master has read the mail.

  - `false` -> No interrupt generated; sent mail is not empty.
  - `true` -> Interrupt generated; mailbox is empty.
  """
  @spec mailbox_empty_interrupt?(t) :: boolean
  def mailbox_empty_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 4),
         do: true,
         else: (_ -> false)
  end

  @doc """
  TEST_INT_INT

  Indicates this master has sent an interrupt to itself.

  - `false` -> No interrupt generated; master has not set the TEST_INT bit in
    STATUS register.
  - `true` -> Interrupt generated; master activates its interrupt pin via the
    TEST_INT bit in STATUS register.
  """
  @spec test_interrupt_pin_interrupt?(t) :: boolean
  def test_interrupt_pin_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 3),
         do: true,
         else: (_ -> false)
  end

  @doc """
  LOCK_GRANT_INT

  Indicates the master has a lock (ownership) on the downstream bus.

  - `false` -> No interrupt generated; this master does not have a lock on the
    downstream bus.
  - `true` -> Interrupt generated; this master has a lock on the downstream bus.
  """
  @spec lock_grant_interrupt?(t) :: boolean
  def lock_grant_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 2),
         do: true,
         else: (_ -> false)
  end

  @doc """
  BUS_LOST_INT

  Indicates the master has involuntarily lost the ownership of the downstream
  bus.

  - `false` -> No interrupt generated; this master is controlling the downstream
    bus.
  - `true` -> Interrupt generated; this master has involuntarily lost the
    control of the downstream bus.
  """
  @spec bus_lost_interrupt?(t) :: boolean
  def bus_lost_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 1),
         do: true,
         else: (_ -> false)
  end

  @doc """
  INT_IN_INT

  Indicates that there is an interrupt from the downstream bus to both the
  granted and non-granted masters.

  - `false` -> No interrupt on interrupt input pin INT_IN.
  - `true` -> Interrupt on interrupt input pin INT_IN.
  """
  @spec interupt_in_interrupt?(t) :: boolean
  def interupt_in_interrupt?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_status(conn),
         true <- get_bool(data, 0),
         do: true,
         else: (_ -> false)
  end

  @doc """
  BUS_HUNG_MSK

  - `false` -> Enable output interrupt when BUS_HUNG function is set.
  - `true` -> Disable output interrupt when BUS_HUNG function is set.
  """
  @spec bus_hung_interrupt_enabled?(t) :: boolean
  def bus_hung_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 6),
         do: true,
         else: (_ -> false)
  end

  @doc """
  MBOX_FULL_MSK

  - `false` -> Enable output interrupt when MBOX_FULL function is set.
  - `true` -> Disable output interrupt when MBOX_FULL function is set.
  """
  @spec mailbox_full_interrupt_enabled?(t) :: boolean
  def mailbox_full_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 5),
         do: true,
         else: (_ -> false)
  end

  @doc """
  MBOX_EMPTY_MSK

  - `false` -> Enable output interrupt when MBOX_EMPTY function is set.
  - `true` -> Disable output interrupt when MBOX_EMPTY function is set.
  """
  @spec mailbox_empty_interrupt_enabled?(t) :: boolean
  def mailbox_empty_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 4),
         do: true,
         else: (_ -> false)
  end

  @doc """
  TEST_INT_MSK

  - `false` -> Enable output interrupt when TEST_INT function is set.
  - `true` -> Disable output interrupt when TEST_INT function is set.
  """
  @spec test_interrupt_interrupt_enabled?(t) :: boolean
  def test_interrupt_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 3),
         do: true,
         else: (_ -> false)
  end

  @doc """
  LOCK_GRANT_MSK

  - `false` -> Enable output interrupt when LOCK_GRANT function is set.
  - `true` -> Disable output interrupt when LOCK_GRANT function is set.
  """
  @spec lock_grant_interrupt_enabled?(t) :: boolean
  def lock_grant_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 2),
         do: true,
         else: (_ -> false)
  end

  @doc """
  BUS_LOST_MSK

  - `false` -> Enable output interrupt when BUS_LOST function is set.
  - `true` -> Disable output interrupt when BUS_LOST function is set.
  """
  @spec bus_lost_interrupt_enabled?(t) :: boolean
  def bus_lost_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 1),
         do: true,
         else: (_ -> false)
  end

  @doc """
  INT_IN_MSK

  - `false` -> Enable output interrupt when INT_IN function is set.
  - `true` -> Disable output interrupt when INT_IN function is set.
  """
  @spec interrupt_in_interrupt_enabled?(t) :: boolean
  def interrupt_in_interrupt_enabled?(%PCA9641{conn: conn}) do
    with {:ok, data} <- Registers.read_interrupt_mask(conn),
         false <- get_bool(data, 0),
         do: true,
         else: (_ -> false)
  end

  @doc """
  Read shared mailbox.
  """
  @spec read_mailbox(t) :: {:ok, mailbox_data, t} | {:error, term}
  def read_mailbox(%PCA9641{conn: conn} = dev) do
    with {:ok, <<lsb>>} <- Registers.read_mailbox_lsb(conn),
         {:ok, <<msb>>} <- Registers.read_mailbox_msb(conn),
         do: {:ok, <<msb, lsb>>, %{dev | conn: conn}}
  end

  @doc """
  Write shared mailbox.
  """
  @spec write_mailbox(t, mailbox_data) :: {:ok, t} | {:error, term}
  def write_mailbox(%PCA9641{conn: conn} = dev, <<msb, lsb>>) do
    with {:ok, conn} <- Registers.write_mailbox_lsb(conn, <<lsb>>),
         {:ok, conn} <- Registers.write_mailbox_msb(conn, <<msb>>),
         do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  Abandon the downstream bus.
  """
  @spec abandon_downstream_bus(t) :: {:ok, t} | {:error, term}
  def abandon_downstream_bus(%PCA9641{conn: conn} = dev) do
    with {:ok, conn} <- Registers.write_control(conn, <<0>>), do: {:ok, %{dev | conn: conn}}
  end

  @doc """
  Waits for downstream bus initialisation to succeed.

  Waits for a maximum of 1 second.
  """
  @spec wait_for_bus_init(t) :: {:ok, t} | {:error, :bus_init_fail}
  def wait_for_bus_init(conn), do: do_wait_for_bus_init(conn, 0)

  defp do_wait_for_bus_init(_conn, 10), do: {:error, :bus_init_fail}

  defp do_wait_for_bus_init(%PCA9641{} = conn, i) do
    if bus_init?(conn) do
      :timer.sleep(100)
      do_wait_for_bus_init(conn, i + 1)
    else
      if bus_initialisation_failed?(conn),
        do: {:error, :bus_init_fail},
        else: {:ok, conn}
    end
  end
end
