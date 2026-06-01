defmodule ProgramCallTest do
  use ExUnit.Case

  # External call encoded layout (20 bytes with empty params):
  #   0    ST      0x01
  #   1-2  SL      20 (little-endian)
  #   3    event
  #   4    prefix  0x0D
  #   5-12 name    8 bytes
  #  13-15 ext     3 bytes
  #    16  seq     0x00
  #    17  type    0x0C (program_object)
  #  18-19 params  <<0,2>> (empty PLEN)

  describe "new/6" do
    test "stores all fields" do
      pc = ProgramCall.new(:pc_event_initializer, :pc_prefix_program_call,
                           "SSGCA001", "PGM", <<>>, [])
      assert pc.segment_type == :program_call
      assert pc.event == :pc_event_initializer
      assert pc.prefix == :pc_prefix_program_call
      assert pc.object_name == "SSGCA001"
      assert pc.object_ext == "PGM"
      assert pc.parameters == []
    end
  end

  describe "encode/1 — external call" do
    setup do
      pc = ProgramCall.new(:pc_event_initializer, :pc_prefix_program_call,
                           "SSGCA001", "PGM", <<>>, [])
      %{pc: pc, encoded: ObjectEncoder.encode(pc)}
    end

    test "ST byte is 0x01", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x01
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "event byte for initializer is 0x02", %{encoded: e} do
      <<_::binary-3, event, _::binary>> = e
      assert event == 0x02
    end

    test "event byte for post_processor is 0x04" do
      pc = ProgramCall.new(:pc_event_post_processor, :pc_prefix_program_call,
                           "SSGCA001", "PGM", <<>>, [])
      <<_::binary-3, event, _::binary>> = ObjectEncoder.encode(pc)
      assert event == 0x04
    end

    test "event byte for help_processor is 0x08" do
      pc = ProgramCall.new(:pc_event_help_processor, :pc_prefix_program_call,
                           "SSGCA001", "PGM", <<>>, [])
      <<_::binary-3, event, _::binary>> = ObjectEncoder.encode(pc)
      assert event == 0x08
    end

    test "prefix byte is 0x0D", %{encoded: e} do
      <<_::binary-4, prefix, _::binary>> = e
      assert prefix == 0x0D
    end

    test "object name occupies bytes 5-12", %{encoded: e} do
      <<_::binary-5, name::binary-8, _::binary>> = e
      assert name == "SSGCA001"
    end

    test "object ext occupies bytes 13-15", %{encoded: e} do
      <<_::binary-13, ext::binary-3, _::binary>> = e
      assert ext == "PGM"
    end

    test "sequence byte is 0x00", %{encoded: e} do
      <<_::binary-16, seq, _::binary>> = e
      assert seq == 0x00
    end

    test "type byte is 0x0C (program_object)", %{encoded: e} do
      <<_::binary-17, type, _::binary>> = e
      assert type == 0x0C
    end

    test "parameters are appended", %{encoded: e} do
      # Empty param list → <<0, 2>> (2-byte PLEN only)
      <<_::binary-18, params::binary>> = e
      assert params == <<0, 2>>
    end

    test "with parameters, SL grows" do
      pc_empty = ProgramCall.new(:pc_event_initializer, :pc_prefix_program_call,
                                 "SSGCA001", "PGM", <<>>, [])
      pc_param = ProgramCall.new(:pc_event_initializer, :pc_prefix_program_call,
                                 "SSGCA001", "PGM", <<>>, [<<"COND">>])
      assert byte_size(ObjectEncoder.encode(pc_param)) >
               byte_size(ObjectEncoder.encode(pc_empty))
    end
  end

  describe "encode/1 — embedded call" do
    setup do
      pc = ProgramCall.new(:pc_event_initializer, :pc_prefix_program_embedded,
                           "", "", <<0xDE, 0xAD>>, [])
      %{pc: pc, encoded: ObjectEncoder.encode(pc)}
    end

    test "ST byte is 0x01", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x01
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prefix byte is 0x0F", %{encoded: e} do
      <<_::binary-4, prefix, _::binary>> = e
      assert prefix == 0x0F
    end

    test "embedded object bytes are present", %{encoded: e} do
      # layout: ST(1) + SL(2) + event(1) + prefix(1) + offset(2) + params(2) + embedded
      <<_::binary-9, embedded::binary>> = e
      assert embedded == <<0xDE, 0xAD>>
    end
  end
end
