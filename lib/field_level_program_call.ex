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

# TODO: See how to merge this with ProgramCall

defmodule FieldLevelProgramCall do
  @moduledoc """
  Represents a field-level program call in the Prodigy object model.
  """

  defstruct [
    :segment_type,
    :segment_length,
    :event,
    :field_name,
    :prefix,
    :object_name,
    :object_ext,
    :offset,
    :embedded_object,
    :parameters
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          segment_length: non_neg_integer(),
          event: ObjectTypes.pc_event(),
          field_name: non_neg_integer(),
          prefix: ObjectTypes.pc_prefix(),
          object_name: binary(),
          object_ext: binary(),
          offset: integer(),
          embedded_object: binary(),
          parameters: list(binary())
        }

  @spec new(ObjectTypes.pc_event(), non_neg_integer(), ObjectTypes.pc_prefix(), binary(), binary(), binary(), list(binary())) ::
          FieldLevelProgramCall.t()
  def new(pc_event, field_name, pc_prefix, object_name, object_ext, embedded_object, parameters) do
    %FieldLevelProgramCall{
      segment_type: :field_level_program_call,
      segment_length: 0,
      event: pc_event,
      field_name: field_name,
      prefix: pc_prefix,
      object_name: object_name,
      object_ext: object_ext,
      # Default offset, can be set later
      offset: 0,
      embedded_object: embedded_object,
      parameters: parameters
    }
  end

  defimpl ObjectEncoder, for: FieldLevelProgramCall do
    use ObjectConstants

    def encode(%FieldLevelProgramCall{} = flpc_segment) do
      parameters_buffer = ObjectUtils.make_params_buffer(flpc_segment.parameters)
      parameters_length = byte_size(parameters_buffer)

      case flpc_segment.prefix do
        :pc_prefix_program_call ->
          o_name = ObjectUtils.edit_length(flpc_segment.object_name, 8)
          o_ext = ObjectUtils.edit_length(flpc_segment.object_ext, 3)

          segment_length =
              1 + # segment_type
              2 + # segment_length
              1 + # event
              1 + # field_name
              1 + # prefix
              13 + # object_name, object_ext, 0, 0x0c
              parameters_length

          <<
            @segment_value_map[flpc_segment.segment_type],
            segment_length::16-little,
            @pc_event_value_map[flpc_segment.event],
            flpc_segment.field_name::8,
            @pc_prefix_value_map[flpc_segment.prefix],
            o_name::binary-size(8),
            o_ext::binary-size(3),
            <<0x00::8>>, # reserved byte
            <<0x0c::8>>, # reserved byte
            parameters_buffer::binary
          >>

        :pc_prefix_program_embedded ->
          segment_length =
              1 + # segment_type
              2 + # segment_length
              1 + # event
              1 + # field_name
              1 + # prefix
              2 + # program offset
              parameters_length +
              byte_size(flpc_segment.embedded_object)

          <<
            @segment_value_map[flpc_segment.segment_type],
            segment_length::16-little,
            @pc_event_value_map[flpc_segment.event],
            flpc_segment.field_name::8,
            @pc_prefix_value_map[flpc_segment.prefix],
            parameters_length::16-little,
            parameters_buffer::binary,
            flpc_segment.embedded_object::binary
          >>
      end
    end
  end
end
