defmodule ProgramDataTest do
  use ExUnit.Case

  # Layout:
  #   0    ST     0x61
  #   1-2  SL     little-endian, inclusive
  #   3    type   0x01 = TBOL program, 0x02 = application data
  #   4+   data   variable

  describe "new/2" do
    test "stores type and data for TBOL" do
      pd = ProgramData.new(:program_data_tbol, <<0xDE, 0xAD>>)
      assert pd.segment_type == :program_data
      assert pd.program_data_type == :program_data_tbol
      assert pd.data == <<0xDE, 0xAD>>
    end

    test "stores type and data for application data" do
      pd = ProgramData.new(:program_data_application, <<1, 2, 3>>)
      assert pd.program_data_type == :program_data_application
      assert pd.data == <<1, 2, 3>>
    end

    test "segment_length is 4 plus data size" do
      data = <<0, 1, 2, 3, 4>>
      pd = ProgramData.new(:program_data_tbol, data)
      assert pd.segment_length == 4 + byte_size(data)
    end
  end

  describe "encode/1" do
    test "ST byte is 0x61" do
      pd = ProgramData.new(:program_data_tbol, <<>>)
      <<st, _::binary>> = ObjectEncoder.encode(pd)
      assert st == 0x61
    end

    test "SL equals total encoded size" do
      pd = ProgramData.new(:program_data_application, <<"hello">>)
      encoded = ObjectEncoder.encode(pd)
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "type byte 0x01 for TBOL program" do
      pd = ProgramData.new(:program_data_tbol, <<>>)
      <<_st, _sl::16-little, type, _::binary>> = ObjectEncoder.encode(pd)
      assert type == 0x01
    end

    test "type byte 0x02 for application data" do
      pd = ProgramData.new(:program_data_application, <<>>)
      <<_st, _sl::16-little, type, _::binary>> = ObjectEncoder.encode(pd)
      assert type == 0x02
    end

    test "data bytes follow the type byte" do
      data = <<0xCA, 0xFE, 0xBA, 0xBE>>
      pd = ProgramData.new(:program_data_tbol, data)
      <<_st, _sl::16-little, _type, payload::binary>> = ObjectEncoder.encode(pd)
      assert payload == data
    end

    test "empty data produces 4-byte encoding" do
      pd = ProgramData.new(:program_data_tbol, <<>>)
      assert byte_size(ObjectEncoder.encode(pd)) == 4
    end
  end
end
