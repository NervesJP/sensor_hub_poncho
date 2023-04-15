defmodule Tsl2561.Config do
  defstruct gain: :gain_1x,
            int_time: :it_402_ms

  def new, do: struct(__MODULE__)
  def new(opts), do: struct(__MODULE__, opts)

  def to_timing_byte(config) do
    reserved = 0
    manual = 0

    <<integer::8>> = <<
      reserved::3,
      gain(config.gain)::1,
      manual::1,
      reserved::1,
      int_time(config.int_time)::2
    >>

    integer
  end

  defp gain(:gain_1x), do: 0b0
  defp gain(:gain_16x), do: 0b1

  defp int_time(:it_13_7_ms), do: 0b00
  defp int_time(:it_101_ms), do: 0b01
  defp int_time(:it_402_ms), do: 0b10
end
