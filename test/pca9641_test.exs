defmodule PCA9641Test do
  use ExUnit.Case, async: true
  use Mimic
  alias PCA9641.Registers, as: Registers
  alias Wafer.Driver.Fake, as: Driver

  describe "acquire/1" do
    test "fails when called without a connection" do
      assert {:error, _} = PCA9641.acquire([])
    end

    test "returns a device struct" do
      assert {:ok, %PCA9641{}} = PCA9641.acquire(conn: Driver.acquire([]))
    end
  end

  describe "verify_identity/1" do
    test "succeeds when the register contains the correct value" do
      Registers
      |> expect(:read_id, 1, fn _conn -> {:ok, <<0x38>>} end)

      assert {:ok, _conn} = PCA9641.verify_identity(conn())
    end

    test "fails when the register contains an incorrect value" do
      Registers
      |> expect(:read_id, 1, fn _conn -> {:ok, <<0x13>>} end)

      assert {:error, _} = PCA9641.verify_identity(conn())
    end
  end

  describe "request_downstream_bus/1" do
    test "writes to the control register and then polls until bus init completes" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b00000001>> = callback.(<<0>>)
        {:ok, conn}
      end)
      |> expect(:read_control, 1, fn _conn ->
        {:ok, <<0b0000>>}
      end)
      |> expect(:read_status, 1, fn _conn ->
        {:ok, <<0b00>>}
      end)

      assert {:ok, _conn} = PCA9641.request_downstream_bus(conn())
    end
  end

  describe "priority?/1" do
    test "reads byte 7 of CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b10000000} end)

      assert PCA9641.priority?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.priority?(conn())
    end
  end

  describe "priority/2" do
    test "writes to bit 7 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b10000000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.priority(conn(), true)
    end
  end

  describe "downstream_disconnect_on_timeout?/1" do
    test "reads bit 6 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b01000000} end)

      assert PCA9641.downstream_disconnect_on_timeout?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.downstream_disconnect_on_timeout?(conn())
    end
  end

  describe "downstream_disconnect_on_timeout/2" do
    test "writes to bit 6 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b01000000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.downstream_disconnect_on_timeout(conn(), true)
    end
  end

  describe "idle_timer_disconnect?/1" do
    test "reads bit 6 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b00100000} end)

      assert PCA9641.idle_timer_disconnect?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.idle_timer_disconnect?(conn())
    end
  end

  describe "idle_timer_disconnect/2" do
    test "writes to bit 5 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b00100000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.idle_timer_disconnect(conn(), true)
    end
  end

  describe "smbus_software_reset?/1" do
    test "reads bit 4 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b00010000} end)

      assert PCA9641.smbus_software_reset?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.smbus_software_reset?(conn())
    end
  end

  describe "smbus_software_reset/2" do
    test "writes to bit 4 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b00010000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.smbus_software_reset(conn(), true)
    end
  end

  describe "bus_init?/1" do
    test "reads bit 3 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b00001000} end)

      assert PCA9641.bus_init?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.bus_init?(conn())
    end
  end

  describe "bus_init/2" do
    test "writes to bit 3 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b00001000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.bus_init(conn(), true)
    end
  end

  describe "bus_connect?/1" do
    test "reads bit 2 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b00000100} end)

      assert PCA9641.bus_connect?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.bus_connect?(conn())
    end
  end

  describe "bus_connect/2" do
    test "writes to bit 2 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b00000100>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.bus_connect(conn(), true)
    end
  end

  describe "lock_grant?/1" do
    test "reads bit 1 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b00000010} end)

      assert PCA9641.lock_grant?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.lock_grant?(conn())
    end
  end

  describe "lock_request?/1" do
    test "reads bit 0 from CONTROL" do
      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0b00000001} end)

      assert PCA9641.lock_request?(conn())

      Registers
      |> expect(:read_control, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.lock_request?(conn())
    end
  end

  describe "lock_request/2" do
    test "writes to bit 0 of CONTROL" do
      Registers
      |> expect(:update_control, 1, fn conn, callback ->
        assert <<0b00000001>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.lock_request(conn(), true)
    end
  end

  describe "sda_becomes_io?/1" do
    test "reads bit 7 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b10000000} end)

      assert PCA9641.sda_becomes_io?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.sda_becomes_io?(conn())
    end
  end

  describe "sda_becomes_io/2" do
    test "writes to bit 7 of STATUS" do
      Registers
      |> expect(:update_status, 1, fn conn, callback ->
        assert <<0b10000000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.sda_becomes_io(conn(), true)
    end
  end

  describe "scl_becomes_io?/1" do
    test "reads bit 6 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b01000000} end)

      assert PCA9641.scl_becomes_io?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.scl_becomes_io?(conn())
    end
  end

  describe "scl_becomes_io/2" do
    test "writes to bit 6 of STATUS" do
      Registers
      |> expect(:update_status, 1, fn conn, callback ->
        assert <<0b01000000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.scl_becomes_io(conn(), true)
    end
  end

  describe "test_interrupt_pin?/1" do
    test "reads bit 5 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b00100000} end)

      assert PCA9641.test_interrupt_pin?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.test_interrupt_pin?(conn())
    end
  end

  describe "test_interrupt_pin/2" do
    test "writes to bit 5 of STATUS" do
      Registers
      |> expect(:update_status, 1, fn conn, callback ->
        assert <<0b00100000>> = callback.(<<0>>)
        {:ok, conn}
      end)

      PCA9641.test_interrupt_pin(conn(), true)
    end
  end

  describe "mailbox_full?/1" do
    test "reads bit 4 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b00010000} end)

      assert PCA9641.mailbox_full?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.mailbox_full?(conn())
    end
  end

  describe "mailbox_empty?/1" do
    test "reads bit 3 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b00001000} end)

      assert PCA9641.mailbox_empty?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.mailbox_empty?(conn())
    end
  end

  describe "bus_hung?/1" do
    test "reads bit 2 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b00000100} end)

      assert PCA9641.bus_hung?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.bus_hung?(conn())
    end
  end

  describe "bus_initialisation_failed?/1" do
    test "reads bit 1 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b00000010} end)

      assert PCA9641.bus_initialisation_failed?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.bus_initialisation_failed?(conn())
    end
  end

  describe "other_lock?/1" do
    test "reads bit 0 of STATUS" do
      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0b00000001} end)

      assert PCA9641.other_lock?(conn())

      Registers
      |> expect(:read_status, 1, fn _conn -> {:ok, 0} end)

      refute PCA9641.other_lock?(conn())
    end
  end

  describe "reserve_time/1" do
    test "returns the contents of the RESERVE_TIME register" do
      Registers
      |> expect(:read_reserve_time, 1, fn _conn ->
        {:ok, <<123>>}
      end)

      assert {:ok, 123, _conn} = PCA9641.reserve_time(conn())
    end
  end

  describe "reserve_time/2" do
    test "sets the contents of the RESERVE_TIME register" do
      Registers
      |> expect(:write_reserve_time, 1, fn conn, ms ->
        assert ms == <<123>>
        {:ok, conn}
      end)

      assert {:ok, _conn} = PCA9641.reserve_time(conn(), 123)
    end
  end

  describe "interrupt_reason/1" do
    test "returns :bus_hung when bit 6 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b01000000>>}
      end)

      assert {:ok, [:bus_hung]} = PCA9641.interrupt_reason(conn())
    end

    test "returns :mbox_full when bit 5 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b00100000>>}
      end)

      assert {:ok, [:mbox_full]} = PCA9641.interrupt_reason(conn())
    end

    test "returns :mbox_empty when bit 4 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b00010000>>}
      end)

      assert {:ok, [:mbox_empty]} = PCA9641.interrupt_reason(conn())
    end

    test "returns :test_int when bit 3 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b00001000>>}
      end)

      assert {:ok, [:test_int]} = PCA9641.interrupt_reason(conn())
    end

    test "returns :lock_grant when bit 2 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b00000100>>}
      end)

      assert {:ok, [:lock_grant]} = PCA9641.interrupt_reason(conn())
    end

    test "returns :bus_lost when bit 1 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b00000010>>}
      end)

      assert {:ok, [:bus_lost]} = PCA9641.interrupt_reason(conn())
    end

    test "returns :int_in when bit 0 of INTERRUPT_STATUS is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, <<0b00000001>>}
      end)

      assert {:ok, [:int_in]} = PCA9641.interrupt_reason(conn())
    end
  end

  describe "interrupt_clear/2" do
    test "writes all ones to INTERRUPT_STATUS when passed `:all`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b01111111
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), :all)
    end

    test "writes INTERRUPT_STATUS bit 5 high when passed `[:mbox_full]`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b00100000
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), [:mbox_full])
    end

    test "writes INTERRUPT_STATUS bit 4 high when passed `[:mbox_empty]`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b00010000
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), [:mbox_empty])
    end

    test "writes INTERRUPT_STATUS bit 3 high when passed `[:test_int]`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b00001000
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), [:test_int])
    end

    test "writes INTERRUPT_STATUS bit 2 high when passed `[:lock_grant]`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b00000100
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), [:lock_grant])
    end

    test "writes INTERRUPT_STATUS bit 1 high when passed `[:bus_lost]`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b00000010
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), [:bus_lost])
    end

    test "writes INTERRUPT_STATUS bit 0 high when passed `[:int_in]`" do
      Registers
      |> expect(:write_interrupt_status, 1, fn conn, <<data>> ->
        assert data == 0b00000001
        {:ok, conn}
      end)

      PCA9641.interrupt_clear(conn(), [:int_in])
    end
  end

  describe "interrupt_enable/2" do
    test "writes all zeroes when called with `:all`" do
      Registers
      |> expect(:write_interrupt_mask, 1, fn conn, <<data>> ->
        assert data == 0
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), :all)
    end

    test "writes all ones when called with `:none`" do
      Registers
      |> expect(:write_interrupt_mask, 1, fn conn, <<data>> ->
        assert data == 0b01111111
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), :none)
    end

    test "writes INTERRUPT_MASK bit 6 low when called with [:bus_hung]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b10111111>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:bus_hung])
    end

    test "writes INTERRUPT_MASK bit 5 low when called with [:mbox_full]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b11011111>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:mbox_full])
    end

    test "writes INTERRUPT_MASK bit 4 low when called with [:mbox_empty]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b11101111>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:mbox_empty])
    end

    test "writes INTERRUPT_MASK bit 3 low when called with [:test_int]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b11110111>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:test_int])
    end

    test "writes INTERRUPT_MASK bit 2 low when called with [:lock_grant]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b11111011>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:lock_grant])
    end

    test "writes INTERRUPT_MASK bit 1 low when called with [:bus_lost]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b11111101>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:bus_lost])
    end

    test "writes INTERRUPT_MASK bit 0 low when called with [:int_in]" do
      Registers
      |> expect(:update_interrupt_mask, 1, fn conn, callback ->
        assert <<0b11111110>> = callback.(<<0xFF>>)
        {:ok, conn}
      end)

      PCA9641.interrupt_enable(conn(), [:int_in])
    end
  end

  describe "interrupt_enabled/1" do
    test "returns [:bus_hung] when INTERRUPT_MASK bit 6 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b10111111}
      end)

      assert {:ok, [:bus_hung]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns [:mbox_full] when INTERRUPT_MASK bit 5 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11011111}
      end)

      assert {:ok, [:mbox_full]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns [:mbox_empty] when INTERRUPT_MASK bit 4 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11101111}
      end)

      assert {:ok, [:mbox_empty]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns [:test_int] when INTERRUPT_MASK bit 3 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11110111}
      end)

      assert {:ok, [:test_int]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns [:lock_grant] when INTERRUPT_MASK bit 2 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11111011}
      end)

      assert {:ok, [:lock_grant]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns [:bus_lost] when INTERRUPT_MASK bit 1 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11111101}
      end)

      assert {:ok, [:bus_lost]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns [:int_in] when INTERRUPT_MASK bit 0 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11111110}
      end)

      assert {:ok, [:int_in]} = PCA9641.interrupt_enabled(conn())
    end

    test "returns all interrupts when all INTERRUPT_MASK bits are low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0}
      end)

      assert {:ok, interrupts} = PCA9641.interrupt_enabled(conn())
      assert :bus_hung in interrupts
      assert :mbox_full in interrupts
      assert :mbox_empty in interrupts
      assert :test_int in interrupts
      assert :lock_grant in interrupts
      assert :bus_lost in interrupts
      assert :int_in in interrupts
    end

    test "returns no interrupts when all INTERRUPT_MASK bits are high" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0x7F}
      end)

      assert {:ok, []} = PCA9641.interrupt_enabled(conn())
    end
  end

  describe "bus_hung_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 6 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b01000000}
      end)

      assert PCA9641.bus_hung_interrupt?(conn())
    end
  end

  describe "mailbox_full_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 5 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b00100000}
      end)

      assert PCA9641.mailbox_full_interrupt?(conn())
    end
  end

  describe "mailbox_empty_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 4 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b00010000}
      end)

      assert PCA9641.mailbox_empty_interrupt?(conn())
    end
  end

  describe "test_interrupt_pin_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 3 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b00001000}
      end)

      assert PCA9641.test_interrupt_pin_interrupt?(conn())
    end
  end

  describe "lock_grant_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 2 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b00000100}
      end)

      assert PCA9641.lock_grant_interrupt?(conn())
    end
  end

  describe "bus_lost_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 1 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b00000010}
      end)

      assert PCA9641.bus_lost_interrupt?(conn())
    end
  end

  describe "interupt_in_interrupt?/1" do
    test "returns `true` when INTERRUPT_STATUS bit 0 is high" do
      Registers
      |> expect(:read_interrupt_status, 1, fn _conn ->
        {:ok, 0b00000001}
      end)

      assert PCA9641.interupt_in_interrupt?(conn())
    end
  end

  describe "bus_hung_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 6 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b10111111}
      end)

      assert PCA9641.bus_hung_interrupt_enabled?(conn())
    end
  end

  describe "mailbox_full_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 5 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11011111}
      end)

      assert PCA9641.mailbox_full_interrupt_enabled?(conn())
    end
  end

  describe "mailbox_empty_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 4 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11101111}
      end)

      assert PCA9641.mailbox_empty_interrupt_enabled?(conn())
    end
  end

  describe "test_interrupt_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 3 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11110111}
      end)

      assert PCA9641.test_interrupt_interrupt_enabled?(conn())
    end
  end

  describe "lock_grant_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 2 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11111011}
      end)

      assert PCA9641.lock_grant_interrupt_enabled?(conn())
    end
  end

  describe "bus_lost_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 1 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11111101}
      end)

      assert PCA9641.bus_lost_interrupt_enabled?(conn())
    end
  end

  describe "interrupt_in_interrupt_enabled?/1" do
    test "returns `true` when INTERRUPT_MASK bit 0 is low" do
      Registers
      |> expect(:read_interrupt_mask, 1, fn _conn ->
        {:ok, 0b11111110}
      end)

      assert PCA9641.interrupt_in_interrupt_enabled?(conn())
    end
  end

  describe "read_mailbox/1" do
    test "returns the contents of the MAILBOX register" do
      Registers
      |> expect(:read_mailbox_msb, 1, fn _conn ->
        {:ok, <<0x1>>}
      end)
      |> expect(:read_mailbox_lsb, 1, fn _conn ->
        {:ok, <<0x2>>}
      end)

      assert {:ok, <<0x1, 0x2>>, _conn} = PCA9641.read_mailbox(conn())
    end
  end

  describe "write_mailbox/2" do
    test "writes the contents of the MAILBOX register" do
      Registers
      |> expect(:write_mailbox_msb, 1, fn conn, data ->
        assert <<0x1>> == data
        {:ok, conn}
      end)
      |> expect(:write_mailbox_lsb, 1, fn conn, data ->
        assert <<0x2>> == data
        {:ok, conn}
      end)

      assert {:ok, _conn} = PCA9641.write_mailbox(conn(), <<0x1, 0x2>>)
    end
  end

  describe "abandon_downstream_bus/1" do
    test "writes the CONTROL register to zero" do
      Registers
      |> expect(:write_control, 1, fn conn, data ->
        assert <<0>> == data
        {:ok, conn}
      end)

      assert {:ok, _conn} = PCA9641.abandon_downstream_bus(conn())
    end
  end

  defp conn do
    with {:ok, conn} <- Driver.acquire([]),
         {:ok, conn} <- PCA9641.acquire(conn: conn),
         do: conn
  end
end
