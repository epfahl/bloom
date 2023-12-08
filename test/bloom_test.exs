defmodule BloomTest do
  use ExUnit.Case
  doctest Bloom

  test "create, insert, and test" do
    bloom =
      Bloom.new(100, 0.01, array_type: :map)
      |> Bloom.put("inserted")

    assert Bloom.member?(bloom, "inserted")
    assert not Bloom.member?(bloom, "not inserted")
  end
end
