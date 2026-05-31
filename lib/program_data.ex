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

defmodule ProgramData do
  @moduledoc """
  Represents a Program Data segment (ST = X'61') in the Prodigy object model.
  Occurs only in a Program Object. Contains either compiled TBOL code or application
  data to be used by a program.
  """

  defstruct [
    :segment_type,
    :segment_length,
    :program_data_type,
    :data
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          segment_length: non_neg_integer(),
          program_data_type: ObjectTypes.program_data_type(),
          data: binary()
        }

  @spec new(ObjectTypes.program_data_type(), binary()) :: ProgramData.t()
  def new(program_data_type, data) do
    segment_length = 4 + byte_size(data)

    %ProgramData{
      segment_type: :program_data,
      segment_length: segment_length,
      program_data_type: program_data_type,
      data: data
    }
  end

  defimpl ObjectEncoder, for: ProgramData do
    use ObjectConstants

    def encode(%ProgramData{} = pd) do
      <<
        @segment_value_map[:program_data],
        pd.segment_length::16-little,
        @program_data_type_value_map[pd.program_data_type],
        pd.data::binary
      >>
    end
  end
end
