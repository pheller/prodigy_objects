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

defmodule StandardMenu do
  @moduledoc """
  Builds the standard-menu call (`XXOPSM00`) that makes a page's numbered
  fields navigate.

  A standard menu is not its own segment type: it is an ordinary
  `ProgramCall` to `XXOPSM00PGM` whose parameters carry the menu. This module
  assembles those parameters so callers do not have to know their order or
  framing.

  ## Where the format came from

  Derived from objects recovered from the service - `NH00CF4JB` and
  `NH00CF4KB`, a working HEADLINE NEWS pair - and cross-checked against the
  parameter framing of simpler calls in `NH000000PG`. `menu_params/1` is
  covered by a test that reproduces `NH00CF4JB`'s segment byte for byte.

  Six parameters, in order:

      P1  processor list: [count:1] then that many 13-byte OBJIDs
      P2  mode byte
      P3  [pages:1] then per action: OBJID, and optionally 'P' + a
          length-prefixed parameter for the destination
      P4  display attributes
      P5  menu attributes
      P6  action attributes

  ## Navigating with a parameter

  The recovered pair shows how a menu reaches a sibling body without a page
  template of its own: the action navigates to the SHARED page template and
  passes the body to display as the destination parameter. One template
  serves every screen in the application, told each time which element to
  show - which is why the service's caches hold one `NH000000PG` and many
  bodies.
  """

  @menu_program "XXOPSM00PGM"

  # Type byte for a program object, as it appears inside an OBJID.
  @type_program 0x0C

  # Action 1 is Navigate; type 0 is an ordinary field rather than a TTX
  # Assistant MENU field.
  @action_navigate 0x01
  @type_plain 0x00

  # Menus here are single-page.
  @page_one 0x01

  @fg_default 7
  @bg_default 0
  # Field state 3 in a display entry is an action field.
  @state_action 3

  @doc """
  An OBJID: an 11-character name, a sequence and a type, as 13 bytes.

  `name` is padded or truncated to 11 characters, so callers may pass the
  bare name.
  """
  @spec objid(binary(), non_neg_integer(), non_neg_integer()) :: binary()
  def objid(name, sequence, type) do
    <<ObjectUtils.edit_length(name, 11)::binary, sequence, type>>
  end

  @doc """
  A destination parameter: the `'P'` tag, a two-byte length, and the payload.

  Used to hand the page template the element it should display.
  """
  @spec destination(binary()) :: binary()
  def destination(payload) when is_binary(payload) do
    <<?P, byte_size(payload)::16-big, payload::binary>>
  end

  @doc """
  The six parameters of a standard-menu call.

  Options:

    * `:mode` - menu mode byte, default 3
    * `:processors` - OBJIDs for mode 0, default none
    * `:pages` - page byte leading P3, default 0
    * `:next_page` - what NEXT reaches from this page, as an OBJID followed by
      any destination parameter. This is P3's real job: the recovered
      NH00CF4JB has empty choice and action lists and uses its menu only to
      name NH00CF4KB as its successor.
    * `:actions` - one entry per numbered choice, each the OBJID (plus any
      destination parameter) the choice navigates to. P4's choice-to-offset
      map and P6's action list are built from these.
    * `:display_attrs`, `:menu_attrs`, `:action_attrs` - overrides for the
      attribute blocks, if the defaults do not suit.

  With no actions the defaults reproduce NH00CF4JB's parameters exactly.
  """
  @spec menu_params(keyword()) :: [binary()]
  def menu_params(opts \\ []) do
    processors = Keyword.get(opts, :processors, [])
    mode = Keyword.get(opts, :mode, 3)
    pages = Keyword.get(opts, :pages, 0)
    next_page = Keyword.get(opts, :next_page) || <<>>
    targets = Keyword.get(opts, :actions, [])

    entries = Enum.map(targets, &(<<@action_navigate, @type_plain>> <> &1))

    [
      <<length(processors)>> <> IO.iodata_to_binary(processors),
      <<mode>>,
      <<pages>> <> next_page,
      Keyword.get(opts, :choice_attrs) || choice_map(entries),
      Keyword.get(opts, :display_attrs) || display_attrs(length(entries)),
      Keyword.get(opts, :action_attrs) || action_attrs(entries)
    ]
  end

  # P4: [page][len:2] then [choice][offset into P6's action list:2] per choice.
  defp choice_map(entries) do
    {rows, _} =
      Enum.map_reduce(Enum.with_index(entries, 1), 0, fn {e, choice}, off ->
        {<<choice, off::16-big>>, off + 1 + byte_size(e)}
      end)

    body = IO.iodata_to_binary(rows)
    <<@page_one, byte_size(body)::16-big>> <> body
  end

  # P5: [page][len:2][init cursor PEV] then a display entry per field,
  # terminated by a zero byte.
  defp display_attrs(count) do
    body =
      <<0>> <>
        IO.iodata_to_binary(
          for pev <- 1..count//1, do: <<pev, @fg_default, @bg_default, @state_action, 0::16>>
        ) <> <<0>>

    <<@page_one, byte_size(body)::16-big>> <> body
  end

  # P6: [page][len:2] then [PEV] + entry per action, terminated by a zero byte.
  defp action_attrs(entries) do
    body =
      IO.iodata_to_binary(for {e, pev} <- Enum.with_index(entries, 1), do: <<pev>> <> e) <> <<0>>

    <<@page_one, byte_size(body)::16-big>> <> body
  end

  @doc """
  A `ProgramCall` to the standard menu, ready to add to an object.

  `event` is the program-call event; the recovered objects use
  `:pc_event_post_processor`.
  """
  @spec new(ObjectTypes.pc_event(), keyword()) :: ProgramCall.t()
  def new(event, opts \\ []) do
    ProgramCall.new(
      event,
      :pc_prefix_program_call,
      String.slice(@menu_program, 0, 8),
      String.slice(@menu_program, 8, 3),
      <<>>,
      menu_params(opts)
    )
    |> Map.put(:object_type, @type_program)
  end
end
