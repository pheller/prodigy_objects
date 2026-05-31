# Copyright 2026, Ralph Richard Cook
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

defmodule PageElementSelector do
  @moduledoc """
  Represents a Page Element Selector segment (ST = X'20') in the Prodigy object model.
  Calls a TBOL selector program that writes the OBJID of the desired PEO into the
  GEV slot SYS_SELECTED_OBJECT_ID. Only one selector or element call is allowed per PTO.
  """

  defstruct [
    :segment_type,
    :partition_id,
    :priority,
    :prefix,
    :object_name,
    :object_ext,
    :offset,
    :embedded_object,
    :parameters
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          partition_id: non_neg_integer(),
          priority: non_neg_integer(),
          prefix: ObjectTypes.pc_prefix(),
          object_name: binary(),
          object_ext: binary(),
          offset: integer(),
          embedded_object: binary(),
          parameters: list(binary())
        }

  @spec new(non_neg_integer(), ObjectTypes.pc_prefix(), binary(), binary(), list(binary())) :: PageElementSelector.t()
  def new(partition_id, prefix, object_name, object_ext, parameters) do
    new(partition_id, prefix, object_name, object_ext, <<>>, parameters)
  end

  @spec new(non_neg_integer(), ObjectTypes.pc_prefix(), binary(), binary(), binary(), list(binary())) :: PageElementSelector.t()
  def new(partition_id, prefix, object_name, object_ext, embedded_object, parameters) do
    %PageElementSelector{
      segment_type: :page_element_selector,
      partition_id: partition_id,
      priority: 0x00,
      prefix: prefix,
      object_name: object_name,
      object_ext: object_ext,
      offset: 0,
      embedded_object: embedded_object,
      parameters: parameters
    }
  end

  defimpl ObjectEncoder, for: PageElementSelector do
    use ObjectConstants

    def encode(%PageElementSelector{} = pes) do
      parameters_buffer = ObjectUtils.make_params_buffer(pes.parameters)
      parameters_length = byte_size(parameters_buffer)

      case pes.prefix do
        :pc_prefix_program_call ->
          o_name = ObjectUtils.edit_length(pes.object_name, 8)
          o_ext = ObjectUtils.edit_length(pes.object_ext, 3)

          segment_length =
            1 + # segment_type
            2 + # segment_length
            1 + # partition_id
            1 + # priority
            1 + # prefix
            13 + # object_name(8) + object_ext(3) + sequence(1) + type(1)
            parameters_length

          <<
            @segment_value_map[:page_element_selector],
            segment_length::16-little,
            pes.partition_id,
            pes.priority,
            @pc_prefix_value_map[pes.prefix],
            o_name::binary-size(8),
            o_ext::binary-size(3),
            0x00,                              # sequence byte
            @object_value_map[:program_object],
            parameters_buffer::binary
          >>

        :pc_prefix_program_embedded ->
          segment_length =
            1 + # segment_type
            2 + # segment_length
            1 + # partition_id
            1 + # priority
            1 + # prefix
            2 + # offset
            parameters_length +
            byte_size(pes.embedded_object)

          <<
            @segment_value_map[:page_element_selector],
            segment_length::16-little,
            pes.partition_id,
            pes.priority,
            @pc_prefix_value_map[pes.prefix],
            parameters_length::16-big,         # offset = PLEN (H/L per spec)
            parameters_buffer::binary,
            pes.embedded_object::binary
          >>
      end
    end
  end
end
