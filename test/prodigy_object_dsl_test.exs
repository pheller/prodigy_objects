defmodule ProdigyObjectDSLTest do
  use ExUnit.Case
  use ProdigyObjectDSL

  # ---------------------------------------------------------------------------
  # Object macros — verify they produce %Header{} with the right object_type
  # ---------------------------------------------------------------------------

  describe "page_format_object/3" do
    test "produces a Header with object_type :page_format_object" do
      obj = page_format_object "SSGC0001", "FMT" do
        partition_definition(1, {0, 0}, {240, 200})
      end
      assert %Header{} = obj
      assert obj.object_type == :page_format_object
    end

    test "collects multiple segments" do
      obj = page_format_object "SSGC0001", "FMT" do
        partition_definition(1, {0, 0}, {240, 100})
        partition_definition(2, {0, 100}, {240, 100})
      end
      assert length(obj.object_list) == 2
    end

    test "single-expression block works" do
      obj = page_format_object "SSGC0001", "FMT" do
        partition_definition(1, {0, 0}, {240, 200})
      end
      assert length(obj.object_list) == 1
    end
  end

  describe "page_template_object/3" do
    test "produces a Header with object_type :page_template_object" do
      obj = page_template_object "SSGC0001", "PG1" do
        page_format_call(:pc_prefix_program_call, "SSGC0001", "FMT")
      end
      assert %Header{} = obj
      assert obj.object_type == :page_template_object
    end

    test "collects multiple segments" do
      obj = page_template_object "SSGC0001", "PG1" do
        page_format_call(:pc_prefix_program_call, "SSGC0001", "FMT")
        page_element_call(1, :pc_prefix_program_call, "SSGC0001", "BB1")
        keyword_navigation()
      end
      assert length(obj.object_list) == 3
    end
  end

  describe "page_element_object/3" do
    test "produces a Header with object_type :page_element_object" do
      obj = page_element_object "SSGC0001", "BB1" do
        presentation_data()
      end
      assert %Header{} = obj
      assert obj.object_type == :page_element_object
    end
  end

  describe "program_object/3" do
    test "produces a Header with object_type :program_object" do
      obj = program_object "SSGCA001", "PGM" do
        program_data(:program_data_application, <<1, 2, 3>>)
      end
      assert %Header{} = obj
      assert obj.object_type == :program_object
    end
  end

  describe "window_object/3" do
    test "produces a Header with object_type :window_object" do
      obj = window_object "SSGCW001", "WIN" do
        partition_definition(1, {40, 40}, {160, 120})
      end
      assert %Header{} = obj
      assert obj.object_type == :window_object
    end
  end

  # ---------------------------------------------------------------------------
  # Variable re-use — a segment bound to a variable can appear in multiple objects
  # ---------------------------------------------------------------------------

  describe "segment variable reuse" do
    test "a segment variable can be referenced inside a block" do
      shared_pd = partition_definition(1, {0, 0}, {240, 200})

      obj1 = page_format_object "SSGC0001", "FM1" do
        shared_pd
      end

      obj2 = page_format_object "SSGC0002", "FM2" do
        shared_pd
      end

      assert hd(obj1.object_list) == hd(obj2.object_list)
    end
  end

  # ---------------------------------------------------------------------------
  # Segment functions — verify they return the right struct types
  # ---------------------------------------------------------------------------

  describe "segment functions" do
    test "page_format_call/3 returns %PageFormatCall{}" do
      seg = page_format_call(:pc_prefix_program_call, "SSGC0001", "FMT")
      assert %PageFormatCall{} = seg
      assert seg.segment_type == :page_format_call
    end

    test "page_element_call/4 returns %PageElementCall{}" do
      seg = page_element_call(1, :pc_prefix_program_call, "SSGC0001", "BB1")
      assert %PageElementCall{} = seg
      assert seg.segment_type == :page_element_call
    end

    test "page_element_selector/5 returns %PageElementSelector{}" do
      seg = page_element_selector(1, :pc_prefix_program_call, "SSGCA001", "PGM", [])
      assert %PageElementSelector{} = seg
      assert seg.segment_type == :page_element_selector
    end

    test "partition_definition/3 returns %PartitionDefinition{}" do
      seg = partition_definition(1, {0, 0}, {240, 200})
      assert %PartitionDefinition{} = seg
      assert seg.segment_type == :partition_definition
    end

    test "presentation_data/0 returns %PresentationData{}" do
      seg = presentation_data()
      assert %PresentationData{} = seg
      assert seg.segment_type == :presentation_data
    end

    test "presentation_data/2 returns %PresentationData{} with data" do
      seg = presentation_data(:presentation_data_naplps, <<0x01>>)
      assert %PresentationData{} = seg
    end

    test "program_data/2 returns %ProgramData{}" do
      seg = program_data(:program_data_application, <<1, 2>>)
      assert %ProgramData{} = seg
      assert seg.segment_type == :program_data
    end

    test "keyword_navigation/0 returns %KeywordNavigation{}" do
      seg = keyword_navigation()
      assert %KeywordNavigation{} = seg
      assert seg.segment_type == :keyword_navigation
    end

    test "keyword_navigation/2 returns %KeywordNavigation{} with fields" do
      seg = keyword_navigation("111000001.BFD  ", "GETFIT")
      assert %KeywordNavigation{} = seg
      assert seg.guide_bfd != nil
    end

    test "embedded_object/1 returns %EmbeddedObject{}" do
      seg = embedded_object(<<0xAB, 0xCD>>)
      assert %EmbeddedObject{} = seg
      assert seg.segment_type == :embedded_object
    end

    test "custom_text/3 returns %CustomText{}" do
      seg = custom_text(1, 7, 0)
      assert %CustomText{} = seg
      assert seg.segment_type == :custom_text
    end

    test "custom_cursor/3 returns %CustomCursor{}" do
      seg = custom_cursor(1, {8, 8}, <<0x01>>)
      assert %CustomCursor{} = seg
      assert seg.segment_type == :custom_cursor
    end

    test "field_definition/8 returns %FieldDefinition{}" do
      seg = field_definition(:active, :alphanumeric, {10, 20}, {80, 10}, 1, 0, 0, {10, 20})
      assert %FieldDefinition{} = seg
      assert seg.segment_type == :field_definition
    end
  end
end
