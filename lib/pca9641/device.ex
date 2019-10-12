defmodule PCA9641.Device do
  alias PCA9641.{Commands, Device}
  use GenServer
  require Logger

  @moduledoc """
  A process to represent a single PCA9641 device.
  """

  @default_config %{}

  @type device_name :: term

  @doc """
  Acquire a lock on the downstream bus.
  """
  @spec acquire_bus(device_name | pid) :: :ok | {:error, term}
  def acquire_bus(pid) when is_pid(pid), do: GenServer.call(pid, :acquire_bus)

  def acquire_bus(device_name),
    do: GenServer.call({:via, Registry, {PCA9641.Registry, device_name}}, :acquire_bus)

  @doc """
  Release the lock on the downstream bus.
  """
  @spec release_bus(device_name | pid) :: :ok | {:error, term}
  def release_bus(pid) when is_pid(pid), do: GenServer.call(pid, :release_bus)

  def release_bus(device_name),
    do: GenServer.call({:via, Registry, {PCA9641.Registry, device_name}}, :release_bus)

  @doc false
  def start_link(config), do: GenServer.start_link(Device, config)

  @impl true
  def init(%{bus: bus, address: address} = config) do
    state = Map.merge(@default_config, config)
    name = device_name(state)

    {:ok, _} = Registry.register(PCA9641.Registry, name, self())
    Process.flag(:trap_exit, true)

    with {:ok, pid} <- Commands.start_link(bus, address),
         {:ok, 0x38} <- Commands.id(pid),
         state <- Map.put(state, :i2c, pid),
         state <- Map.put(state, :name, name) do
      Logger.info("Connected to PCA9641 device on #{inspect(name)}")
      {:ok, state}
    else
      {:ok, id} when is_integer(id) -> {:error, "Incorrect device ID #{id}"}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def terminate(_reason, %{i2c: pid, name: name}) do
    Logger.info("Disconnecting from PCA9641 device on #{inspect(name)}")
    Commands.release(pid)
  end

  @impl true
  def handle_call(:acquire_bus, _from, %{i2c: pid} = state) do
    {:reply, Commands.request_downstream_bus(pid), state}
  end

  def handle_call(:release_bus, _from, %{i2c: pid} = state) do
    {:reply, Commands.abandon_downstream_bus(pid), state}
  end

  defp device_name(%{bus: bus, address: address} = state) do
    state
    |> Map.get(:name, {bus, address})
  end

  @doc false
  def child_spec(config) do
    %{
      id: {PCA9641.Device, device_name(config)},
      start: {PCA9641.Device, :start_link, [config]},
      restart: :transient
    }
  end
end
