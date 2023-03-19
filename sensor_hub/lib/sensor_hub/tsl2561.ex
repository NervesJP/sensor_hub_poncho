defmodule TSL2561 do
  import Bitwise

  alias Circuits.I2C

  @sensor_address 0x29

  @spec open_bus() :: {:ok, reference()}
  def open_bus() do
    I2C.open("i2c-1")
  end

  def select_register(bus, register_address) do
    I2C.write(bus, @sensor_address, <<0b1000::4, register_address::4>>)
  end

  def power_up(bus) do
    select_register(bus, 0x0)
    :ok = I2C.write(bus, @sensor_address, <<0x03>>)
    I2C.read(bus, @sensor_address, 1)
  end

  def power_down(bus) do
    select_register(bus, 0x0)
    :ok = I2C.write(bus, @sensor_address, <<0x00>>)
    I2C.read(bus, @sensor_address, 1)
  end

  def read_adc(bus) do
    select_register(bus, 0xC)
    <<ch_0::little-16, ch_1::little-16>> = I2C.read!(bus, @sensor_address, 4)
    {ch_0, ch_1}
  end

  def read_adc0(bus) do
    select_register(bus, 0xC)
    <<value::little-16>> = I2C.read!(bus, @sensor_address, 2)
    value
  end

  def read_adc1(bus) do
    select_register(bus, 0xE)
    <<value::little-16>> = I2C.read!(bus, @sensor_address, 2)
    value
  end

  def read_id(bus) do
    select_register(bus, 0xA)
    <<part_no::4, rev_no::4>> = I2C.read!(bus, @sensor_address, 1)
    {part_no, rev_no}
  end

  def to_lux({0 = _adc_0, _adc_1}), do: 0

  def to_lux({adc_0, adc_1}) do
    # NOTE: Gain が 1x で使う場合は 2**4 倍する
    #              16x で使う場合は不要
    adc_0 = adc_0 <<< 4
    adc_1 = adc_1 <<< 4

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
