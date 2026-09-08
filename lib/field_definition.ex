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

  @doc """
  A field definition with no cursor.

  Recovered objects carry both shapes: `NH00CF4JB` from the service and the
  traced HEADLINE NEWS bodies stop after `text_id`, giving a 13-byte segment,
  while others go on to name a cursor. Passing `nil` for `cursor_id` selects
  the shorter form, and the encoder leaves off the cursor bytes entirely.
  """
  @spec new(
          ObjectTypes.field_state(),
          ObjectTypes.field_format(),
          tuple(),
          tuple(),
          non_neg_integer(),
          non_neg_integer()
        ) ::
          FieldDefinition.t()
  def new(field_state, field_format, origin, size, field_name, text_id) do
    new(field_state, field_format, origin, size, field_name, text_id, nil, nil)
  end

  def new(field_state, field_format, origin, size, field_name, text_id, cursor_id, cursor_origin) do
    # size of "static data" is segment_type = 1, segment_length = 2, pdt_tye = 1

    # segment_type,
    # segment_length
    # field_state
    # field_format
    # origin x, origin y
    # size x, size y
    # field_name
    # text_id
    # cursor_id and its origin
    segment_length =
      1 +
        2 +
        1 +
        1 +
        3 +
        3 +
        1 +
        1 +
        if(is_nil(cursor_id), do: 0, else: 1 + 3)

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
        cursor(field_definition)::binary
      >>
    end

    defp cursor(%FieldDefinition{cursor_id: nil}), do: <<>>

    defp cursor(%FieldDefinition{} = fd),
      do: <<fd.cursor_id::8, ObjectUtils.naplps_coords(fd.cursor_origin)::binary>>
  end
end
