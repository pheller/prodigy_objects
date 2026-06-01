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

defmodule CustomCursor do
  @moduledoc """
  Represents a custom cursor in the Prodigy object model.
  """

  defstruct [
    :segment_type,
    :segment_length,
    :cursor_id,
    :cursor_size,
    :naplps
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          segment_length: non_neg_integer(),
          cursor_id: non_neg_integer(),
          cursor_size: ObjectTypes.xy(),
          naplps: binary()
        }

  @spec new(non_neg_integer(), ObjectTypes.xy(), binary()) :: CustomCursor.t()
  def new(cursor_id, cursor_size, naplps) do
    # segment_type + segment_length + cursor_origin
    segment_length = 1 + 2 + 3

    %CustomCursor{
      segment_type: :custom_cursor,
      segment_length: segment_length,
      cursor_id: cursor_id,
      cursor_size: cursor_size,
      naplps: naplps
    }
  end

  defimpl ObjectEncoder, for: CustomCursor do
    use ObjectConstants

    def encode(%CustomCursor{} = custom_cursor) do
      length =
        1 + # segment_type
        2 + # segment_length
        1 + # cursor_id
        3 + # cursor_size x, y
        byte_size(custom_cursor.naplps)

      <<
        @segment_value_map[:custom_cursor],
        length::16-little,
        custom_cursor.cursor_id::8,
        ObjectUtils.naplps_coords(custom_cursor.cursor_size)::binary,
        custom_cursor.naplps::binary
      >>
    end
  end
end
