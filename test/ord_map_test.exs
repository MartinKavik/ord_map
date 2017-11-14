defmodule OrdMapTest do
  use ExUnit.Case, async: true
  use OrdMap

  doctest OrdMap

  test "Get a nested value" do
    ordMap = o(%{"a" => 2, "nestedOrdMap" => o(%{"b" => 3})})
    assert ordMap["nestedOrdMap"]["b"] == 3
  end

  test "Update nested value" do
    users = o(%{"john" => o(%{age: 27}), "meg" => o(%{age: 23})})
    result = put_in(users["john"][:age], 28)
    expected = o(%{"john" => o(%{age: 28}), "meg" => o(%{age: 23})})
    assert result == expected
  end

  test "Map values" do
    users = o(%{"john" => o(%{age: 27}), "meg" => o(%{age: 23})})

    result =
      users
      |> Enum.map(fn {name, data} -> {name, data |> OrdMap.replace(:age, 10)} end)
      |> OrdMap.from_tuples()

    expected = o(%{"john" => o(%{age: 10}), "meg" => o(%{age: 10})})
    assert result == expected
  end
end
