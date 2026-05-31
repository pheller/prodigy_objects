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

defmodule PageElementCall do
  @moduledoc """
  Represents a Page Element Call segment (ST = X'21') in the Prodigy object model.
  Used in a Page Template Object or Window Element Object to call a Page Element Object
  that contains the display data for a given partition.
  """

  defstruct [
    :segment_type,
    :partition_id,
    :priority,
    :prefix,
    :object_name,
    :object_ext,
    :offset,
    :embedded_object
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          partition_id: non_neg_integer(),
          priority: non_neg_integer(),
          prefix: ObjectTypes.pc_prefix(),
          object_name: binary(),
          object_ext: binary(),
          offset: integer(),
          embedded_object: binary()
        }

  @spec new(non_neg_integer(), ObjectTypes.pc_prefix(), binary(), binary()) :: PageElementCall.t()
  def new(partition_id, prefix, object_name, object_ext) do
    new(partition_id, prefix, object_name, object_ext, <<>>)
  end

  @spec new(non_neg_integer(), ObjectTypes.pc_prefix(), binary(), binary(), binary()) :: PageElementCall.t()
  def new(partition_id, prefix, object_name, object_ext, embedded_object) do
    %PageElementCall{
      segment_type: :page_element_call,
      partition_id: partition_id,
      priority: 0x00,
      prefix: prefix,
      object_name: object_name,
      object_ext: object_ext,
      offset: 0,
      embedded_object: embedded_object
    }
  end

  defimpl ObjectEncoder, for: PageElementCall do
    use ObjectConstants

    def encode(%PageElementCall{} = pec) do
      case pec.prefix do
        :pc_prefix_program_call ->
          o_name = ObjectUtils.edit_length(pec.object_name, 8)
          o_ext = ObjectUtils.edit_length(pec.object_ext, 3)

          segment_length =
            1 + # segment_type
            2 + # segment_length
            1 + # partition_id
            1 + # priority
            1 + # prefix
            13  # object_name(8) + object_ext(3) + sequence(1) + type(1)

          <<
            @segment_value_map[:page_element_call],
            segment_length::16-little,
            pec.partition_id,
            pec.priority,
            @pc_prefix_value_map[pec.prefix],
            o_name::binary-size(8),
            o_ext::binary-size(3) #, Claude put in the next two things incorrectly?
            # 0x00,                              # sequence byte
            # @object_value_map[:page_element_object]
          >>

        :pc_prefix_program_embedded ->
          segment_length =
            1 + # segment_type
            2 + # segment_length
            1 + # partition_id
            1 + # priority
            1 + # prefix
            2 + # offset
            byte_size(pec.embedded_object)

          <<
            @segment_value_map[:page_element_call],
            segment_length::16-little,
            pec.partition_id,
            pec.priority,
            @pc_prefix_value_map[pec.prefix],
            0::16-little,                      # offset = 0, embedded object follows immediately
            pec.embedded_object::binary
          >>
      end
    end
  end
end
