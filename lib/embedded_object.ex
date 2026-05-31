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

defmodule EmbeddedObject do
  @moduledoc """
  Represents an Embedded Object segment (ST = X'52') in the Prodigy object model.
  Wraps the binary of an object that is embedded inline within another object and
  addressed by offset from a calling segment.
  """

  defstruct [
    :segment_type,
    :data
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          data: binary()
        }

  @spec new(binary()) :: EmbeddedObject.t()
  def new(data) do
    %EmbeddedObject{
      segment_type: :embedded_object,
      data: data
    }
  end

  defimpl ObjectEncoder, for: EmbeddedObject do
    use ObjectConstants

    def encode(%EmbeddedObject{} = eo) do
      segment_length =
        1 + # segment_type
        2 + # segment_length
        byte_size(eo.data)

      <<
        @segment_value_map[:embedded_object],
        segment_length::16-little,
        eo.data::binary
      >>
    end
  end
end
