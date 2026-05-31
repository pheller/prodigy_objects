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

defmodule ObjectTypes do
  @type object_type ::
          :page_format_object
          | :page_template_object
          | :page_element_object
          | :program_object
          | :window_object
  @type object_type_value :: 0x00 | 0x04 | 0x08 | 0x0C | 0x0E
  @type object_type_value_map :: %{
          object_type() => object_type_value()
        }
  @type value_object_type_map :: %{object_type_value() => object_type()}

  @type segment_type ::
          :program_call
          | :field_level_program_call
          | :field_definition
          | :custom_text
          | :custom_cursor
          | :page_element_selector
          | :page_element_call
          | :page_format_call
          | :partition_definition
          | :presentation_data
          | :embedded_object
          | :program_data
          | :keyword_navigation
  @type segment_type_value ::
          0x01 | 0x02 | 0x04 | 0x0A | 0x0B | 0x20 | 0x21 | 0x31 | 0x33 | 0x51 | 0x52 | 0x61 | 0x71
  @type segment_type_value_map :: %{
          segment_type() => segment_type_value()
        }
  @type value_segment_type_map :: %{segment_type_value() => segment_type()}

  @type presentation_data_type ::
          :presentation_data_naplps
          | :presentation_data_ascii
  @type presentation_data_type_value :: 0x01 | 0x02
  @type presentation_data_type_value_map :: %{
          presentation_data_type() => presentation_data_type_value()
        }
  @type value_presentation_data_type_map :: %{
          presentation_data_type_value() => presentation_data_type()
        }

  @type field_state ::
          :field_state_input_field
          | :field_state_display_only
          | :field_state_action_field
  @type field_state_value :: 0x20 | 0x40 | 0x80
  @type field_state_value_map :: %{
          field_state() => field_state_value()
        }
  @type value_field_state_map :: %{field_state_value() => field_state()}

  @type field_format ::
          :field_format_alphanumeric
          | :field_format_numeric
          | :field_format_date
          | :field_format_time
          | :field_format_currency
          | :field_format_custom
  @type field_format_value :: 0x80 | 0x40 | 0x20 | 0x10 | 0x00
  @type field_format_value_map :: %{
          field_format() => field_format_value()
        }
  @type value_field_format_map :: %{field_format_value() => field_format()}

  @type pc_event ::
          :pc_event_initializer
          | :pc_event_post_processor
          | :pc_event_help_processor
  @type pc_event_value :: 0x02 | 0x04 | 0x08
  @type pc_event_value_map :: %{
          pc_event() => pc_event_value()
        }
  @type value_pc_event_map :: %{pc_event_value() => pc_event()}

  @type pc_prefix ::
          :pc_prefix_program_call
          | :pc_prefix_program_embedded
  @type pc_prefix_value :: 0x0D | 0x0F
  @type pc_prefix_value_map :: %{
          pc_prefix() => pc_prefix_value()
        }
  @type value_pc_prefix_map :: %{pc_prefix_value() => pc_prefix()}

  @type program_data_type ::
          :program_data_tbol
          | :program_data_application
  @type program_data_type_value :: 0x01 | 0x02
  @type program_data_type_value_map :: %{program_data_type() => program_data_type_value()}
  @type value_program_data_type_map :: %{program_data_type_value() => program_data_type()}

  # x, y coordinates
  @type xy :: {integer(), integer()}

end
