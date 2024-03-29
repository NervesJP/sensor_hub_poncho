defmodule SensorHub.Sensor do
  defstruct [:name, :fields, :read, :convert]

  def new(name) do
    %__MODULE__{
      read: read_fn(name),
      convert: convert_fn(name),
      fields: fields(name),
      name: name
    }
  end

  def fields(SGP30), do: [:co2_eq_ppm, :tvoc_ppb]
  def fields(BMP280), do: [:altitude_m, :pressure_pa, :temperature_c]
  def fields(Tsl2561), do: [:light_lux]

  def read_fn(SGP30), do: fn -> SGP30.state() end
  def read_fn(BMP280), do: fn -> BMP280.measure(BMP280) end
  def read_fn(Tsl2561), do: fn -> Tsl2561.get_measurement() end

  def convert_fn(SGP30) do
    fn reading ->
      Map.take(reading, [:co2_eq_ppm, :tvoc_ppb])
    end
  end

  def convert_fn(BMP280) do
    fn reading ->
      case reading do
        {:ok, measurement} ->
          Map.take(measurement, [:altitude_m, :pressure_pa, :temperature_c])

        _ ->
          %{}
      end
    end
  end

  def convert_fn(Tsl2561) do
    fn data -> %{light_lux: data} end
  end

  def measure(sensor) do
    sensor.read.()
    |> sensor.convert.()
  end
end
