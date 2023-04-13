defmodule Tsl2561.Comm do
  alias Circuits.I2C
  alias Tsl2561.Config

  def open(bus_name) do
    {:ok, bus} = I2C.open(bus_name)
    bus
  end

  def write_timing(config, bus, address) do
    select_register(bus, address, 0x1)

    byte = Config.to_timing_byte(config)
    I2C.write(bus, address, <<byte>>)
  end

  def read(bus, address, config) do
    read_adc(bus, address)
    |> to_lux(config)
  end

  def power_up(bus, address) do
    select_register(bus, address, 0x0)
    :ok = I2C.write(bus, address, <<0x03>>)
    I2C.read(bus, address, 1)
  end

  def power_down(bus, address) do
    select_register(bus, address, 0x0)
    :ok = I2C.write(bus, address, <<0x00>>)
    I2C.read(bus, address, 1)
  end

  defp select_register(bus, address, register_address) do
    I2C.write(bus, address, <<0b1000::4, register_address::4>>)
  end

  defp read_adc(bus, address) do
    select_register(bus, address, 0xC)
    <<ch_0::little-16, ch_1::little-16>> = I2C.read!(bus, address, 4)
    {ch_0, ch_1}
  end

  defp read_adc0(bus, address) do
    select_register(bus, address, 0xC)
    <<value::little-16>> = I2C.read!(bus, address, 2)
    value
  end

  defp read_adc1(bus, address) do
    select_register(bus, address, 0xE)
    <<value::little-16>> = I2C.read!(bus, address, 2)
    value
  end

  defp read_id(bus, address) do
    select_register(bus, address, 0xA)
    <<part_no::4, rev_no::4>> = I2C.read!(bus, address, 1)
    {part_no, rev_no}
  end

  defp to_lux({0 = _adc_0, _adc_1}, _config), do: 0

  defp to_lux({adc_0, adc_1}, config) do
    # NOTE: Gain が 1x で使う場合は 2**4 倍する
    #              16x で使う場合は不要
    {adc_0, adc_1} =
      case config.gain do
        :gain_1x -> {adc_0 * 16, adc_1 * 16}
        :gain_16x -> {adc_0, adc_1}
      end

    ratio = adc_1 / adc_0

    cond do
      ratio > 0 and ratio <= 0.52 -> 0.0315 * adc_0 - 0.0593 * adc_0 * ratio ** 1.4
      ratio > 0.52 and ratio <= 0.65 -> 0.0229 * adc_0 - 0.0291 * adc_1
      ratio > 0.65 and ratio <= 0.80 -> 0.0157 * adc_0 - 0.0180 * adc_1
      ratio > 0.80 and ratio <= 1.30 -> 0.00338 * adc_0 - 0.00260 * adc_1
      ratio > 1.30 -> 0
    end
  end
end
