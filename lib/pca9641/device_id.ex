defimpl Wafer.DeviceID, for: PCA9641 do
  def id(%PCA9641{conn: conn, int_pin: nil}), do: {PCA9641, [conn: Wafer.DeviceID.id(conn)]}

  def id(%PCA9641{conn: conn, int_pin: pin}),
    do: {PCA9641, [conn: Wafer.DeviceID.id(conn), pin: Wafer.DeviceID.id(pin)]}
end
