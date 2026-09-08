# Copyright 2024, Ralph Richard Cook
#
# This file is part of Prodigy Reloaded.
#
# Prodigy Reloaded is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# Prodigy Reloaded is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License along with Prodigy Reloaded. If not,
# see <https://www.gnu.org/licenses/>.

defmodule ObjectUtils do
  # Makes sure a string is exactly the given length, padding with spaces if necessary.
  @spec edit_length(binary(), non_neg_integer()) :: binary()
  def edit_length(text, length),
    do: String.slice(text, 0, length) |> String.pad_trailing(length, " ")

  # Converts a coordinate tuple to a NAPLPS coordinate binary.
  @spec naplps_coords({integer(), integer()}) :: binary()
  def naplps_coords({x, y}) do
    NaplpsWriter.mb_xy(<<>>, {x / 256, y / 256})
  end

  # Puts the length of the buffer inside the buffer, at the offset.
  # Currently assumes 16-little
  @spec inject_length(binary(), non_neg_integer()) :: <<_::16, _::_*8>>
  def inject_length(buffer, offset) do
    length = byte_size(buffer) - offset
    <<buffer::binary-size(offset), length::16-little, buffer::binary-size(length)>>
  end

  @spec make_params_buffer(list(binary())) :: <<_::16, _::_*8>>
  @doc """
  Frame a parameter list.

  `nil` yields no bytes at all - a call with NO parameter area, which is what
  the recovered XXOPSM01 calls carry: they end at the object id. An empty list
  keeps its 2-byte area header, which is the long-standing behavior and what
  the existing tests expect; the two are different on the wire and both occur.
  """
  def make_params_buffer(nil), do: <<>>

  def make_params_buffer(params) do
    params_buffer =
      Enum.reduce(params, <<>>, fn param, acc ->
        acc <> make_one_param(param)
      end)

    # 2 for the length the rest is the parameter data
    length = 2 + byte_size(params_buffer)
    <<length::16-big, params_buffer::binary>>
  end

  @spec make_one_param(binary()) :: <<_::16, _::_*8>>
  defp make_one_param(param_buffer) do
    case param_buffer do
      # An empty parameter is a 0 with the inclusive length
      <<>> ->
        <<0, 3, 0>>

      _ ->
        # 2 for the length the rest is the parameter data
        length = 2 + byte_size(param_buffer)
        <<length::16-big, param_buffer::binary>>
    end
  end
end
