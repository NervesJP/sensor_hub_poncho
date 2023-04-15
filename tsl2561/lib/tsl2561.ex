defmodule Tsl2561 do
  use GenServer
  require Logger

  alias Tsl2561.Comm
  alias Tsl2561.Config

  def start_link(options \\ %{}) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def get_measurement do
    GenServer.call(__MODULE__, :get_measurement)
  end

  @impl true
  def init(%{address: address, i2c_bus_name: bus_name} = args) do
    i2c = Comm.open(bus_name)

    Comm.power_up(i2c, address)

    config =
      args
      |> Map.take([:gain, :int_time])
      |> Config.new()

    Comm.write_timing(config, i2c, address)
    :timer.send_interval(1_000, :measure)

    state = %{
      i2c: i2c,
      address: address,
      config: config,
      last_reading: :no_reading
    }

    {:ok, state}
  end

  @impl true
  def handle_info(
        :measure,
        %{i2c: i2c, address: address, config: config} = state
      ) do
    last_reading = Comm.read(i2c, address, config)
    Logger.debug("last_reading: #{last_reading}")
    updated_with_reading = %{state | last_reading: last_reading}
    {:noreply, updated_with_reading}
  end

  @impl true
  def handle_call(:get_measurement, _from, state) do
    {:reply, state.last_reading, state}
  end
end
