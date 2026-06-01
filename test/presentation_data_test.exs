defmodule PresentationDataTest do
  use ExUnit.Case

  describe "new/0" do
    test "creates struct with presentation_data segment type" do
      pd = PresentationData.new()
      assert pd.segment_type == :presentation_data
    end
  end

  describe "new/2" do
    test "stores type and data" do
      pd = PresentationData.new(:presentation_data_ascii, "hello")
      assert pd.pdt_type == :presentation_data_ascii
      assert pd.presentation_data == "hello"
    end

    test "segment_length is 4 plus data size" do
      data = "hello"
      pd = PresentationData.new(:presentation_data_ascii, data)
      assert pd.segment_length == 4 + byte_size(data)
    end
  end

  describe "encode/1" do
    test "ST byte is 0x51" do
      pd = PresentationData.new(:presentation_data_ascii, "")
      <<st, _::binary>> = ObjectEncoder.encode(pd)
      assert st == 0x51
    end

    test "SL equals total encoded size" do
      pd = PresentationData.new(:presentation_data_ascii, "test")
      encoded = ObjectEncoder.encode(pd)
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "type byte 0x01 for NAPLPS" do
      pd = PresentationData.new(:presentation_data_naplps, <<>>)
      <<_st, _sl::16-little, type, _::binary>> = ObjectEncoder.encode(pd)
      assert type == 0x01
    end

    test "type byte 0x02 for ASCII" do
      pd = PresentationData.new(:presentation_data_ascii, <<>>)
      <<_st, _sl::16-little, type, _::binary>> = ObjectEncoder.encode(pd)
      assert type == 0x02
    end

    test "data bytes follow the type byte" do
      data = "Hello, Prodigy!"
      pd = PresentationData.new(:presentation_data_ascii, data)
      <<_st, _sl::16-little, _type, payload::binary>> = ObjectEncoder.encode(pd)
      assert payload == data
    end

    test "empty data produces 4-byte encoding" do
      pd = PresentationData.new(:presentation_data_ascii, <<>>)
      assert byte_size(ObjectEncoder.encode(pd)) == 4
    end
  end
end
