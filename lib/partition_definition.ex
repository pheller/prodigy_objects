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

defmodule PartitionDefinition do
  @moduledoc """
  Represents a Partition Definition segment (ST = X'33') in the Prodigy object model.
  Specifies the partition ID, origin (lower-left corner), and size (upper-right corner
  relative to origin) of a screen partition or window. Required in both Page Format Objects
  and Window Element Objects.

  Standard partition IDs: 1, 2, 5, 6, 7, ... = Header/Body/Window; 3 = Ad; 4 = Command Bar.
  """

  defstruct [
    :segment_type,
    :partition_id,
    :origin,
    :size,
    :naplps
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          partition_id: non_neg_integer(),
          origin: ObjectTypes.xy(),
          size: ObjectTypes.xy(),
          naplps: binary()
        }

  @spec new(non_neg_integer(), ObjectTypes.xy(), ObjectTypes.xy()) :: PartitionDefinition.t()
  def new(partition_id, origin, size) do
    new(partition_id, origin, size, <<>>)
  end

  @spec new(non_neg_integer(), ObjectTypes.xy(), ObjectTypes.xy(), binary()) :: PartitionDefinition.t()
  def new(partition_id, origin, size, naplps) do
    %PartitionDefinition{
      segment_type: :partition_definition,
      partition_id: partition_id,
      origin: origin,
      size: size,
      naplps: naplps
    }
  end

  defimpl ObjectEncoder, for: PartitionDefinition do
    use ObjectConstants

    def encode(%PartitionDefinition{} = pd) do
      segment_length =
        1 + # segment_type
        2 + # segment_length
        1 + # partition_id
        3 + # origin (NAPLPS x, y)
        3 + # size (NAPLPS x, y)
        byte_size(pd.naplps)

      <<
        @segment_value_map[:partition_definition],
        segment_length::16-little,
        pd.partition_id,
        ObjectUtils.naplps_coords(pd.origin)::binary,
        ObjectUtils.naplps_coords(pd.size)::binary,
        pd.naplps::binary
      >>
    end
  end
end
