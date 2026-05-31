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

defmodule KeywordNavigation do
  @moduledoc """
  Represents a Keyword/Navigation segment (ST = X'71') in the Prodigy object model.
  Optionally specifies the previous menu OBJID (not used), the BFD of the current PTO
  (guide_bfd), and the keyword used to navigate to the current PTO (current_keyword).
  guide_bfd and current_keyword must both be present or both absent.
  """

  defstruct [
    :segment_type,
    :prev_menu,
    :guide_bfd,
    :current_keyword
  ]

  @type t :: %__MODULE__{
          segment_type: ObjectTypes.segment_type(),
          prev_menu: binary(),
          guide_bfd: binary() | nil,
          current_keyword: binary() | nil
        }

  # prev_menu is 13 bytes; guide_bfd and current_keyword are both absent
  @spec new() :: KeywordNavigation.t()
  def new() do
    %KeywordNavigation{
      segment_type: :keyword_navigation,
      prev_menu: String.duplicate(" ", 13),
      guide_bfd: nil,
      current_keyword: nil
    }
  end

  # guide_bfd is 13 bytes, e.g. "bfdXXXXXX.BFDbb"; current_keyword is up to 13 bytes
  @spec new(binary(), binary()) :: KeywordNavigation.t()
  def new(guide_bfd, current_keyword) do
    %KeywordNavigation{
      segment_type: :keyword_navigation,
      prev_menu: String.duplicate(" ", 13),
      guide_bfd: ObjectUtils.edit_length(guide_bfd, 13),
      current_keyword: ObjectUtils.edit_length(current_keyword, 13)
    }
  end

  defimpl ObjectEncoder, for: KeywordNavigation do
    use ObjectConstants

    def encode(%KeywordNavigation{} = kn) do
      optional =
        if kn.guide_bfd != nil do
          <<kn.guide_bfd::binary-size(13), kn.current_keyword::binary-size(13)>>
        else
          <<>>
        end

      segment_length =
        1 + # segment_type
        2 + # segment_length
        13 + # prev_menu OBJID
        byte_size(optional)

      <<
        @segment_value_map[:keyword_navigation],
        segment_length::16-little,
        kn.prev_menu::binary-size(13),
        optional::binary
      >>
    end
  end
end
