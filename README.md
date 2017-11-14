# OrdMap

[![Hex.pm](https://img.shields.io/hexpm/v/ord_map.svg?style=flat-square)](https://hex.pm/packages/ord_map)

**Ordered map for Elixir lang**

- A set of functions and a macro for working with **ordered maps**.

- An **ordered map** is a *struct* with a *list of key-value tuples* 
where *key* and *value* can be any value.

- It can be serialized to JSON with [Poison](https://github.com/devinus/poison) - you need to add [OrdMap Poison encoder](https://github.com/MartinKavik/ord_map_encoder_poison) to your project dependencies. 

## Usage
```elixir

iex> o%{"foo" => "bar"}
%OrdMap{tuples: [{"foo", "bar"}]}

iex> my_ord_map = OrdMap.new([{"foo", 1}, {"bar", 2}])
iex> OrdMap.get(my_ord_map, "bar")
2

iex> my_ord_map = o%{"foo" => o(%{nested: "something"}), "bar" => "two"}
iex> my_ord_map["foo"][:nested]
"something"

iex> my_ord_map = o%{"foo" => 1, "bar" => 2}
iex> Enum.map my_ord_map, fn {key, value} -> {key, value + 1} end
[{"foo", 2}, {"bar", 3}]

```

## Installation

First, add OrdMap to your mix.exs dependencies:

```elixir
def deps do
  [
    {:ord_map, "~> 0.1.0"}
  ]
end
```

Then, update your dependencies:

```sh-session
$ mix deps.get
```

## License

OrdMap is released under MIT (see [`LICENSE`](LICENSE)).

