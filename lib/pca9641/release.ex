defimpl Wafer.Release, for: PCA9641 do
  def release(%PCA9641{conn: conn, int_pin: pin_conn} = dev) do
    PCA9641.abandon_downstream_bus(dev)
    PCA9641.interrupt_enable(dev, :none)
    PCA9641.interrupt_clear(dev, :all)
    Wafer.Release.release(pin_conn)
    Wafer.Release.release(conn)
  end
end
