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

defmodule ObjectConstants do
  defmacro __using__(_) do
    quote do

      map_swap = fn map -> Map.new(map, fn {key, val} -> {val, key} end) end

      @value_object_map %{
        0x00 => :page_format_object,
        0x04 => :page_template_object,
        0x08 => :page_element_object,
        0x0C => :program_object,
        0x0E => :window_object
      }
      @object_value_map map_swap.(@value_object_map)

      @value_segment_map %{
        0x01 => :program_call,
        0x02 => :field_level_program_call,
        0x04 => :field_definition,
        0x0A => :custom_text,
        0x0B => :custom_cursor,
        0x20 => :page_element_selector,
        0x21 => :page_element_call,
        0x31 => :page_format_call,
        0x33 => :partition_definition,
        0x51 => :presentation_data,
        0x52 => :embedded_object,
        0x61 => :program_data,
        0x71 => :keyword_navigation
      }
      @segment_value_map map_swap.(@value_segment_map)

      @value_presentation_data_type_map %{
        0x01 => :presentation_data_naplps,
        0x02 => :presentation_data_ascii
      }
      @presentation_data_type_value_map map_swap.(@value_presentation_data_type_map)

      @value_field_state_map %{
        0x20 => :field_state_input_field,
        0x40 => :field_state_display_only,
        0x80 => :field_state_action_field
      }
      @field_state_value_map map_swap.(@value_field_state_map)

      @value_field_format_map %{
        0x80 => :field_format_alphabetic,
        0x40 => :field_format_numeric,
        0x20 => :field_format_form,
        0x10 => :field_format_password,
        0x00 => :field_format_alphanumeric
      }
      @field_format_value_map map_swap.(@value_field_format_map)

      @value_pc_event_map %{
        0x02 => :pc_event_initializer,
        0x04 => :pc_event_post_processor,
        0x08 => :pc_event_help_processor
      }
      @pc_event_value_map map_swap.(@value_pc_event_map)

      @value_pc_prefix_map %{
        0x0d => :pc_prefix_program_call,
        0x0f => :pc_prefix_program_embedded
      }
      @pc_prefix_value_map map_swap.(@value_pc_prefix_map)

      @value_program_data_type_map %{
        0x01 => :program_data_tbol,
        0x02 => :program_data_application
      }
      @program_data_type_value_map map_swap.(@value_program_data_type_map)

    end
  end
end
