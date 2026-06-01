defmodule FieldLevelProgramCallTest do
  use ExUnit.Case

  # External call layout (21 bytes with empty params):
  #   0    ST           0x02
  #   1-2  SL           21 (little-endian)
  #   3    event
  #   4    field_name   1 byte
  #   5    prefix       0x0D
  #   6-13 name         8 bytes
  #  14-16 ext          3 bytes
  #    17  seq          0x00
  #    18  type         0x0C
  #  19-20 params       <<0,2>> (empty PLEN)

  describe "new/7" do
    test "stores all fields" do
      flpc = FieldLevelProgramCall.new(:pc_event_post_processor, 1, :pc_prefix_program_call,
                                      "SSGCA010", "PGM", <<>>, [])
      assert flpc.segment_type == :field_level_program_call
      assert flpc.event == :pc_event_post_processor
      assert flpc.field_name == 1
      assert flpc.prefix == :pc_prefix_program_call
      assert flpc.object_name == "SSGCA010"
      assert flpc.object_ext == "PGM"
      assert flpc.parameters == []
    end
  end

  describe "encode/1 — external call" do
    setup do
      flpc = FieldLevelProgramCall.new(:pc_event_post_processor, 2, :pc_prefix_program_call,
                                      "SSGCA010", "PGM", <<>>, [])
      %{flpc: flpc, encoded: ObjectEncoder.encode(flpc)}
    end

    test "ST byte is 0x02", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x02
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "event byte is correct", %{encoded: e} do
      <<_::binary-3, event, _::binary>> = e
      assert event == 0x04  # post_processor
    end

    test "field_name byte follows event", %{encoded: e} do
      <<_::binary-4, field_name, _::binary>> = e
      assert field_name == 2
    end

    test "prefix byte is 0x0D", %{encoded: e} do
      <<_::binary-5, prefix, _::binary>> = e
      assert prefix == 0x0D
    end

    test "object name in OBJID" do
      flpc = FieldLevelProgramCall.new(:pc_event_post_processor, 1, :pc_prefix_program_call,
                                      "SSGCA010", "PGM", <<>>, [])
      <<_::binary-6, name::binary-8, _::binary>> = ObjectEncoder.encode(flpc)
      assert name == "SSGCA010"
    end

    test "with parameters, SL grows" do
      base = FieldLevelProgramCall.new(:pc_event_post_processor, 1, :pc_prefix_program_call,
                                      "SSGCA010", "PGM", <<>>, [])
      with_params = FieldLevelProgramCall.new(:pc_event_post_processor, 1, :pc_prefix_program_call,
                                             "SSGCA010", "PGM", <<>>, [<<0x01>>, <<0x02>>])
      assert byte_size(ObjectEncoder.encode(with_params)) >
               byte_size(ObjectEncoder.encode(base))
    end
  end

  describe "encode/1 — embedded call" do
    setup do
      flpc = FieldLevelProgramCall.new(:pc_event_initializer, 1, :pc_prefix_program_embedded,
                                      "", "", <<0xBE, 0xEF>>, [])
      %{flpc: flpc, encoded: ObjectEncoder.encode(flpc)}
    end

    test "ST byte is 0x02", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x02
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prefix byte is 0x0F", %{encoded: e} do
      # ST(1) + SL(2) + event(1) + field_name(1) + prefix = byte 5
      <<_::binary-5, prefix, _::binary>> = e
      assert prefix == 0x0F
    end

    test "embedded object bytes present" do
      # ST(1)+SL(2)+event(1)+field_name(1)+prefix(1)+offset(2)+params(2) = 10 bytes before embedded
      flpc = FieldLevelProgramCall.new(:pc_event_initializer, 1, :pc_prefix_program_embedded,
                                      "", "", <<0xBE, 0xEF>>, [])
      <<_::binary-10, embedded::binary>> = ObjectEncoder.encode(flpc)
      assert embedded == <<0xBE, 0xEF>>
    end
  end
end
