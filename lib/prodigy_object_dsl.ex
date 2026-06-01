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

defmodule ProdigyObjectDSL do
  @moduledoc """
  DSL for building Prodigy Objects and Segments.

  ## Usage

      use ProdigyObjectDSL

  Each object macro accepts an 8-character name, a type/sequence extension (up to 3 chars),
  and a do-block whose expressions must each evaluate to a segment struct.

  ## Example

      use ProdigyObjectDSL

      pfo = page_format_object "SSGC0001", "FMT" do
        partition_definition(1, {10, 60}, {150, 100})
      end

      pto = page_template_object "SSGC0001", "PG1" do
        page_format_call(:pc_prefix_program_call, "SSGC0001", "FMT")
        page_element_call(1, :pc_prefix_program_call, "SSGC0001", "BB1")
        keyword_navigation("111000001.BFD  ", "GETFIT")
      end

      pdo = program_object "SSGCA001", "PGM" do
        ~TBOL\"\"\"
        LET X = 1
        PRINT X
        \"\"\"
      end

  ## TBOL sigil

  ~TBOL compiles inline TBOL source code at build time. tbolc must be on PATH.
  It writes the source to a temporary .src file, runs tbolc to produce a .cod file,
  reads the compiled binary, and returns a ProgramData segment with the result.
  """

  defmacro __using__(_opts) do
    quote do
      import ProdigyObjectDSL
    end
  end

  # Elixir's parser produces different AST shapes depending on how many
  # expressions appear in a do-block:
  #
  #   - Two or more expressions: {:__block__, meta, [expr1, expr2, ...]}
  #     :__block__ is Elixir's internal AST node for a sequence of expressions.
  #
  #   - Exactly one expression: the expression's own AST node directly —
  #     there is no wrapping :__block__.
  #
  # The object macros pass the do-block's AST to unquote_splicing/1, which
  # requires a plain list of AST nodes. extract_exprs/1 normalises both shapes
  # into that list: it unwraps a :__block__ to get its children, and wraps a
  # single expression in a one-element list.
  defp extract_exprs({:__block__, _, exprs}), do: exprs
  defp extract_exprs(expr), do: [expr]

  # ---------------------------------------------------------------------------
  # Object macros
  # ---------------------------------------------------------------------------

  defmacro page_template_object(name, ext, do: block) do
    exprs = extract_exprs(block)
    quote do
      Header.new(unquote(name), unquote(ext), :page_template_object, [unquote_splicing(exprs)])
    end
  end

  defmacro page_format_object(name, ext, do: block) do
    exprs = extract_exprs(block)
    quote do
      Header.new(unquote(name), unquote(ext), :page_format_object, [unquote_splicing(exprs)])
    end
  end

  defmacro page_element_object(name, ext, do: block) do
    exprs = extract_exprs(block)
    quote do
      Header.new(unquote(name), unquote(ext), :page_element_object, [unquote_splicing(exprs)])
    end
  end

  defmacro program_object(name, ext, do: block) do
    exprs = extract_exprs(block)
    quote do
      Header.new(unquote(name), unquote(ext), :program_object, [unquote_splicing(exprs)])
    end
  end

  defmacro window_object(name, ext, do: block) do
    exprs = extract_exprs(block)
    quote do
      Header.new(unquote(name), unquote(ext), :window_object, [unquote_splicing(exprs)])
    end
  end

  # ---------------------------------------------------------------------------
  # TBOL sigil — compiles TBOL source at build time via tbolc
  # ---------------------------------------------------------------------------

  defmacro sigil_TBOL({:<<>>, _meta, [source]}, _modifiers) do
    base = Path.join(System.tmp_dir!(), "tbol_#{:erlang.unique_integer([:positive, :monotonic])}")
    src_path = base <> ".src"
    cod_path = base <> ".cod"

    File.write!(src_path, source)

    case System.cmd("tbolc", [src_path], stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, code} ->
        File.rm(src_path)
        raise CompileError,
          file: __CALLER__.file,
          line: __CALLER__.line,
          description: "tbolc failed (exit #{code}):\n#{output}"
    end

    compiled = File.read!(cod_path)
    File.rm(src_path)
    File.rm(cod_path)

    quote do
      ProgramData.new(:program_data_tbol, unquote(compiled))
    end
  end

  # ---------------------------------------------------------------------------
  # Segment functions — thin wrappers that return segment structs
  # ---------------------------------------------------------------------------

  # Page Format Call (ST = X'31') — first segment of a Page Template Object
  def page_format_call(prefix, name, ext),
    do: PageFormatCall.new(prefix, name, ext)

  def page_format_call(prefix, name, ext, embedded),
    do: PageFormatCall.new(prefix, name, ext, embedded)

  # Page Element Call (ST = X'21') — calls a PEO for a partition
  def page_element_call(partition_id, prefix, name, ext),
    do: PageElementCall.new(partition_id, prefix, name, ext)

  def page_element_call(partition_id, prefix, name, ext, embedded),
    do: PageElementCall.new(partition_id, prefix, name, ext, embedded)

  # Page Element Selector (ST = X'20') — dynamically selects a PEO via TBOL program
  def page_element_selector(partition_id, prefix, name, ext, params),
    do: PageElementSelector.new(partition_id, prefix, name, ext, params)

  def page_element_selector(partition_id, prefix, name, ext, embedded, params),
    do: PageElementSelector.new(partition_id, prefix, name, ext, embedded, params)

  # Partition Definition (ST = X'33') — defines a partition's position and size
  def partition_definition(partition_id, origin, size),
    do: PartitionDefinition.new(partition_id, origin, size)

  def partition_definition(partition_id, origin, size, naplps),
    do: PartitionDefinition.new(partition_id, origin, size, naplps)

  # Presentation Data (ST = X'51') — NAPLPS or ASCII display data
  def presentation_data(),
    do: PresentationData.new()

  def presentation_data(type, data),
    do: PresentationData.new(type, data)

  # Program Call (ST = X'01') — calls a program object from a page or partition
  def program_call(event, prefix, name, ext, embedded, params),
    do: ProgramCall.new(event, prefix, name, ext, embedded, params)

  # Field Level Program Call (ST = X'02') — attaches a program to a field
  def field_level_program_call(event, field_name, prefix, name, ext, embedded, params),
    do: FieldLevelProgramCall.new(event, field_name, prefix, name, ext, embedded, params)

  # Field Definition (ST = X'04') — names a field and specifies its attributes
  def field_definition(state, format, origin, size, field_name, text_id, cursor_id, cursor_origin),
    do: FieldDefinition.new(state, format, origin, size, field_name, text_id, cursor_id, cursor_origin)

  # Custom Text (ST = X'0A') — foreground/background color override for a field
  def custom_text(ref_id, fg, bg),
    do: CustomText.new(ref_id, fg, bg)

  def custom_text(ref_id, fg, bg, naplps),
    do: CustomText.new(ref_id, fg, bg, naplps)

  # Custom Cursor (ST = X'0B') — NAPLPS-drawn cursor for a field
  def custom_cursor(cursor_id, cursor_size, naplps),
    do: CustomCursor.new(cursor_id, cursor_size, naplps)

  # Keyword / Navigation (ST = X'71') — BFD and keyword for this PTO
  def keyword_navigation(),
    do: KeywordNavigation.new()

  def keyword_navigation(guide_bfd, current_keyword),
    do: KeywordNavigation.new(guide_bfd, current_keyword)

  # Program Data (ST = X'61') — compiled TBOL or application data (prefer ~TBOL for TBOL code)
  def program_data(type, data),
    do: ProgramData.new(type, data)

  # Embedded Object (ST = X'52') — wraps an object binary for inline embedding
  def embedded_object(data),
    do: EmbeddedObject.new(data)
end
