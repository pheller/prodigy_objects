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

defmodule PageFormatCall do
  @moduledoc """
  Represents a Page Format Call segment (ST = X'31') in the Prodigy object model.
  This is the first segment in a Page Template Object. It calls the Page Format Object
  that describes the screen partitions. If object_name starts with "XX", no PFO is called.
  """

  defstruct [
    :segment_type,
    :prefix,
    :object_name,
    :object_ext,
    :offset,
    :embedded_object
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          prefix: ObjectTypes.pc_prefix(),
          object_name: binary(),
          object_ext: binary(),
          offset: integer(),
          embedded_object: binary()
        }

  @spec new(ObjectTypes.pc_prefix(), binary(), binary()) :: PageFormatCall.t()
  def new(prefix, object_name, object_ext) do
    new(prefix, object_name, object_ext, <<>>)
  end

  @spec new(ObjectTypes.pc_prefix(), binary(), binary(), binary()) :: PageFormatCall.t()
  def new(prefix, object_name, object_ext, embedded_object) do
    %PageFormatCall{
      segment_type: :page_format_call,
      prefix: prefix,
      object_name: object_name,
      object_ext: object_ext,
      offset: 0,
      embedded_object: embedded_object
    }
  end

  defimpl ObjectEncoder, for: PageFormatCall do
    use ObjectConstants

    def encode(%PageFormatCall{} = pfc) do
      case pfc.prefix do
        :pc_prefix_program_call ->
          o_name = ObjectUtils.edit_length(pfc.object_name, 8)
          o_ext = ObjectUtils.edit_length(pfc.object_ext, 3)

          segment_length =
            1 + # segment_type
            2 + # segment_length
            1 + # prefix
            13  # object_name(8) + object_ext(3) + sequence(1) + type(1)

          <<
            @segment_value_map[:page_format_call],
            segment_length::16-little,
            @pc_prefix_value_map[pfc.prefix],
            o_name::binary-size(8),
            o_ext::binary-size(3),
            0x00,                              # sequence byte
            @object_value_map[:page_format_object]
          >>

        :pc_prefix_program_embedded ->
          segment_length =
            1 + # segment_type
            2 + # segment_length
            1 + # prefix
            2 + # offset
            byte_size(pfc.embedded_object)

          <<
            @segment_value_map[:page_format_call],
            segment_length::16-little,
            @pc_prefix_value_map[pfc.prefix],
            0::16-little,                      # offset = 0, embedded object follows immediately
            pfc.embedded_object::binary
          >>
      end
    end
  end
end
