defmodule ParamsBufferTest do
  use ExUnit.Case

  test "nil means no parameter area at all" do
    assert ObjectUtils.make_params_buffer(nil) == <<>>
  end

  test "an empty list still frames an empty area, as it always has" do
    assert ObjectUtils.make_params_buffer([]) == <<0, 2>>
  end

  test "a nil-parameter XXOPSM01 call matches the recovered segment length" do
    pc =
      ProgramCall.new(
        :pc_event_post_processor,
        :pc_prefix_program_call,
        "XXOPSM01",
        "PGM",
        <<>>,
        nil
      )

    # 04 0d "XXOPSM01PGM" 00 0c, framed: 3 + 15 = 18 bytes.
    assert byte_size(ObjectEncoder.encode(pc)) == 18
  end

  test "one parameter frames both the area and the value, each counting itself" do
    assert ObjectUtils.make_params_buffer([<<0xAA, 0xBB>>]) ==
             <<0x00, 0x06, 0x00, 0x04, 0xAA, 0xBB>>
  end
end
