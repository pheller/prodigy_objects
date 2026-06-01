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

defmodule FieldDefinition do

  defstruct [
    :segment_type,
    :segment_length,
    :field_state,
    :field_format,
    :origin,
    :size,
    :field_name,
    :text_id,
    :cursor_id,
    :cursor_origin
  ]

  @type t :: %__MODULE__{
    segment_type: ObjectTypes.segment_type(),
    segment_length: non_neg_integer(),
    field_state: ObjectTypes.field_state(),
    field_format: ObjectTypes.field_format(),
    origin: ObjectTypes.xy(),
    size: ObjectTypes.xy(),
    field_name: non_neg_integer(),
    text_id: non_neg_integer(),
    cursor_id: non_neg_integer(),
    cursor_origin: ObjectTypes.xy()
  }

  def new(field_state, field_format, origin, size, field_name, text_id, cursor_id, cursor_origin) do
    # size of "static data" is segment_type = 1, segment_length = 2, pdt_tye = 1

    segment_length =
      1 + # segment_type,
      2 + # segment_length
      1 + # field_state
      1 + # field_format
      3 + # origin x, origin y
      3 + # size x, size y
      1 + # field_name
      1 + # text_id
      1 + # cursor_id
      3   # cursor_origin xy

    %FieldDefinition{
      segment_type: :field_definition,
      segment_length: segment_length,
      field_state: field_state,
      field_format: field_format,
      origin: origin,
      size: size,
      field_name: field_name,
      text_id: text_id,
      cursor_id: cursor_id,
      cursor_origin: cursor_origin
    }
  end

  defimpl ObjectEncoder, for: FieldDefinition do
    use ObjectConstants
    @spec encode(FieldDefinition.t()) :: <<_::32, _::_*8>>
    def encode(%FieldDefinition{} = field_definition) do
      <<
        @segment_value_map[field_definition.segment_type],
        field_definition.segment_length::16-little,
        @field_state_value_map[field_definition.field_state],
        @field_format_value_map[field_definition.field_format],
        ObjectUtils.naplps_coords(field_definition.origin)::binary,
        ObjectUtils.naplps_coords(field_definition.size)::binary,
        field_definition.field_name::8,
        field_definition.text_id::8,
        field_definition.cursor_id::8,
        ObjectUtils.naplps_coords(field_definition.cursor_origin)::binary
      >>
    end
  end
end
