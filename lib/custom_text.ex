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

defmodule CustomText do
  @moduledoc """
  Represents a custom cursor in the Prodigy object model.
  """

  defstruct [
    :segment_type,
    :segment_length,
    :reference_id,
    :foreground_color,
    :background_color,
    :naplps
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          segment_length: non_neg_integer(),
          reference_id: non_neg_integer(),
          foreground_color: non_neg_integer(),
          background_color: non_neg_integer(),
          naplps: binary()
        }

  @spec new(non_neg_integer(), non_neg_integer(),non_neg_integer()) :: CustomCursor.t()
  def new(reference_id, foreground_color, background_color) do
    new(reference_id, foreground_color, background_color, <<>>)
  end

  @spec new(non_neg_integer(), non_neg_integer(),non_neg_integer(),binary()) :: CustomCursor.t()
  def new(reference_id, foreground_color, background_color, naplps) do
    # segment_type + segment_length + cursor_origin
    segment_length = 1 + 2 + 3

    %CustomText{
      segment_type: :custom_text,
      segment_length: segment_length,
      reference_id: reference_id,
      foreground_color: foreground_color,
      background_color: background_color,
      naplps: naplps
    }
  end

  defimpl ObjectEncoder, for: CustomText do
    use ObjectConstants

    def encode(%CustomText{} = custom_text) do
      length =
        1 + # segment_type
        2 + # segment_length
        1 + # reference_id
        1 + # foreground_color
        1 + # background_color
        byte_size(custom_text.naplps)

      <<
        @segment_value_map[:custom_text],
        length::16-little,
        custom_text.reference_id::8,
        custom_text.foreground_color::8,
        custom_text.background_color::8,
        custom_text.naplps::binary
      >>
    end
  end
end
