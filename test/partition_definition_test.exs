defmodule PartitionDefinitionTest do
  use ExUnit.Case

  # Layout (10 bytes with no NAPLPS data):
  #   0    ST           0x33
  #   1-2  SL           10 (little-endian)
  #   3    partition_id
  #   4-6  origin       3 bytes (NAPLPS)
  #   7-9  size         3 bytes (NAPLPS)
  #   10+  naplps       variable

  describe "new/3" do
    test "stores partition_id, origin, size" do
      pd = PartitionDefinition.new(1, {0, 160}, {240, 40})
      assert pd.segment_type == :partition_definition
      assert pd.partition_id == 1
      assert pd.origin == {0, 160}
      assert pd.size == {240, 40}
      assert pd.naplps == <<>>
    end
  end

  describe "new/4" do
    test "stores naplps data" do
      pd = PartitionDefinition.new(2, {0, 40}, {240, 120}, <<0xAB>>)
      assert pd.naplps == <<0xAB>>
    end
  end

  describe "encode/1" do
    test "ST byte is 0x33" do
      pd = PartitionDefinition.new(1, {0, 160}, {240, 40})
      <<st, _::binary>> = ObjectEncoder.encode(pd)
      assert st == 0x33
    end

    test "SL equals total encoded size" do
      pd = PartitionDefinition.new(1, {0, 160}, {240, 40})
      encoded = ObjectEncoder.encode(pd)
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "no NAPLPS data produces 10-byte encoding" do
      pd = PartitionDefinition.new(1, {0, 160}, {240, 40})
      assert byte_size(ObjectEncoder.encode(pd)) == 10
    end

    test "partition_id at byte 3" do
      pd = PartitionDefinition.new(3, {0, 0}, {240, 40})
      <<_::binary-3, partition_id, _::binary>> = ObjectEncoder.encode(pd)
      assert partition_id == 3
    end

    test "origin encoded as NAPLPS coords" do
      pd = PartitionDefinition.new(1, {10, 60}, {150, 100})
      <<_::binary-4, origin::binary-3, _::binary>> = ObjectEncoder.encode(pd)
      assert origin == ObjectUtils.naplps_coords({10, 60})
    end

    test "size encoded as NAPLPS coords" do
      pd = PartitionDefinition.new(1, {10, 60}, {150, 100})
      <<_::binary-7, size::binary-3, _::binary>> = ObjectEncoder.encode(pd)
      assert size == ObjectUtils.naplps_coords({150, 100})
    end

    test "naplps data appended at end" do
      naplps = <<0x01, 0x02, 0x03>>
      pd = PartitionDefinition.new(1, {0, 0}, {240, 200}, naplps)
      <<_::binary-10, tail::binary>> = ObjectEncoder.encode(pd)
      assert tail == naplps
    end

    test "standard partition IDs all encode correctly" do
      for id <- [1, 2, 3, 4, 5, 6] do
        pd = PartitionDefinition.new(id, {0, 0}, {240, 200})
        <<_::binary-3, partition_id, _::binary>> = ObjectEncoder.encode(pd)
        assert partition_id == id
      end
    end
  end
end
