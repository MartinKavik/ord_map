defmodule OrdMap do
  defstruct tuples: nil

  @moduledoc """
  - A set of functions and a macro for working with **ordered maps**.

  - An **ordered map** is a *struct* with a *list of key-value tuples* 
  where *key* and *value* can be any value.

  - It can be serialized to JSON with [Poison](https://github.com/devinus/poison) - you need to add [OrdMap Poison encoder](https://github.com/MartinKavik/ord_map_encoder_poison) to your project dependencies. 

  ## Usage
  ```

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
  """

  @behaviour Access

  @type key :: any
  @type value :: any

  @type tuples :: [{key, value}]
  @type t :: %OrdMap{tuples: tuples}
  @type ord_map :: t

  defmacro __using__(_opts) do
    quote do
      import OrdMap, only: [o: 1]
    end
  end

  @doc """
  Macro transforms `Map` to `t:ord_map/0` during compilation.

  ## Examples

      iex> o%{a: 1, b: 2}
      %OrdMap{tuples: [a: 1, b: 2]}
      iex> o(%{"a" => "x"})
      %OrdMap{tuples: [{"a", "x"}]}      

  """
  defmacro o({type, _meta, args}) when type == :%{} do
    quote do
      %OrdMap{tuples: unquote(args)}
    end
  end

  @doc """

  Deletes the entry in the `t:ord_map/0` having a specific `key`.

  If the `key` does not exist, returns the `t:ord_map/0` unchanged.

  ## Examples
      iex> OrdMap.delete(o(%{"a" => 1, b: 2}), "a")
      o%{b: 2}
      iex> OrdMap.delete(o(%{b: 2}), :a)
      o%{b: 2}
  """
  @spec delete(t | tuples, key) :: t
  def delete(%OrdMap{tuples: tuples}, key), do: delete(tuples, key)
  def delete([], _key), do: [] |> OrdMap.new()

  def delete([h | _] = tuples, key) when is_tuple(h) and tuple_size(h) == 2 do
    Enum.filter(tuples, fn {k, _} -> k != key end) |> OrdMap.new()
  end

  @doc """
  Fetches the value for a specific `key` in the given `t:ord_map/0`.

  If the `key` does not exist, returns `:error`.

  ## Examples

      iex> ord_map = o%{"a" => 1}
      iex> OrdMap.fetch(ord_map, "a")
      {:ok, 1}

      iex> ord_map = o%{}
      iex> OrdMap.fetch(ord_map, "key")
      :error

  """
  @spec fetch(t | tuples, key) :: {:ok, value} | :error
  def fetch(%OrdMap{tuples: tuples}, key), do: fetch(tuples, key)
  def fetch([], _key), do: :error

  def fetch([h | _] = tuples, key) when is_tuple(h) and tuple_size(h) == 2 do
    case List.keyfind(tuples, key, 0) do
      {_, value} -> {:ok, value}
      nil -> :error
    end
  end

  @doc """
  Creates an `t:ord_map/0` from a `t:tuples/0`.

  (Delegates to function `OrdMap.new/1`) 

  ## Examples
      iex> [{:b, 1}, {:a, 2}] |> OrdMap.from_tuples
      o%{b: 1, a: 2}

  """

  @spec from_tuples(tuples) :: t
  defdelegate from_tuples(tuples), to: __MODULE__, as: :new

  @doc """
  Gets the value for a specific `key` in `t:ord_map/0`.

  If `key` is present in `t:ord_map/0` with value `value`, then `value` is
  returned. Otherwise, `default` is returned (which is `nil` unless
  specified otherwise).

  ## Examples

      iex> OrdMap.get(o(%{}), :a)
      nil
      iex> OrdMap.get(o(%{a: 1}), :a)
      1
      iex> OrdMap.get(o(%{a: 1}), :b)
      nil
      iex> OrdMap.get(o(%{"a" => 1}), :b, 3)
      3
      iex> OrdMap.get([{:a, 2}], :a)
      2

  """
  @spec get(t | tuples, key, default :: value) :: value
  def get(term, key, default \\ nil) do
    case fetch(term, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Gets the value from `key` and updates it, all in one pass.

  This `fun` argument receives the value of `key` (or `nil` if `key`
  is not present) and must return a two-element tuple: the "get" value
  (the retrieved value, which can be operated on before being returned)
  and the new value to be stored under `key`. The `fun` may also
  return `:pop`, implying the current value shall be removed from the
  'ord_map' and returned.

  The returned value is a tuple with the "get" value returned by
  `fun` and a new 'ord_map' with the updated value under `key`.

  ## Examples

      iex> OrdMap.get_and_update(o(%{a: 1}), :a, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {1, o%{a: "new value!"}}
      iex> OrdMap.get_and_update(o(%{a: 1}), :b, fn current_value ->
      ...>   {current_value, "new value!"}
      ...> end)
      {nil, o%{a: 1, b: "new value!"}}
      iex> OrdMap.get_and_update(o(%{a: 1}), :a, fn _ -> :pop end)
      {1, o%{}}
      iex> OrdMap.get_and_update(o(%{a: 1}), :b, fn _ -> :pop end)
      {nil, o%{a: 1}}


  """
  @spec get_and_update(t | tuples, key, (value -> {get, value} | :pop)) :: {get, t} when get: term
  def get_and_update(%OrdMap{tuples: tuples}, key, fun), do: get_and_update(tuples, key, fun)
  def get_and_update([], key, fun), do: _get_and_update([], key, fun)

  def get_and_update([h | _] = tuples, key, fun)
      when is_tuple(h) and tuple_size(h) == 2,
      do: _get_and_update(tuples, key, fun)

  defp _get_and_update(tuples, key, fun) when is_list(tuples) and is_function(fun) do
    case tuples |> OrdMap.get(key) |> fun.() do
      {get_value, update_value} ->
        new_data = put(tuples, key, update_value)
        {get_value, new_data}

      :pop ->
        pop(tuples, key)
    end
  end

  @doc """
  Merges two `t:ord_map/0`s into one.

  All keys in `ord_map2` will be added to `ord_map1`, overriding any existing one
  (i.e., the keys in `ord_map2` "have precedence" over the ones in `ord_map1`).

  ## Examples

      iex> OrdMap.merge(o(%{a: 1, b: 2}), o%{a: 3, d: 4})
      o%{a: 3, b: 2, d: 4}

  """
  @spec merge(t, t) :: t
  def merge(ord_map1, ord_map2) do
    List.foldl(ord_map2.tuples, ord_map1.tuples, &List.keystore(&2, elem(&1, 0), 0, &1))
    |> OrdMap.new()
  end

  @doc """
  Creates an empty `t:ord_map/0`.

  (See `new/1` for creating `t:ord_map/0` from other types)

  ## Examples

      iex> OrdMap.new()
      o%{}

  """
  @spec new :: t
  def new(), do: %OrdMap{tuples: []}

  @doc """
  Creates an `t:ord_map/0` from a `Map`,
  from a `t:tuples/0` or from other `t:ord_map/0`.

  (See `new/0` creating an empty `t:ord_map/0`)

  ## Examples

      iex> OrdMap.new(%{a: 2, b: 1})
      o%{a: 2, b: 1}
      iex> OrdMap.new([a: 3, b: 4])
      o%{a: 3, b: 4}
      iex> OrdMap.new(%OrdMap{tuples: [{"a", 5}, {"b", 6}]})
      o%{"a" => 5, "b" => 6}
      iex> OrdMap.new([])
      o%{}

  """
  @spec new(t | map | tuples) :: t
  def new(%OrdMap{} = ord_map), do: ord_map
  def new(%{} = map), do: Map.to_list(map) |> OrdMap.new()
  def new([]), do: %OrdMap{tuples: []}
  def new([h | _] = tuples) when is_tuple(h) and tuple_size(h) == 2, do: %OrdMap{tuples: tuples}

  @doc """
  Returns all keys from `t:ord_map/0`.

  ## Examples

      iex> OrdMap.keys(o%{a: 1, b: 2})
      [:a, :b]
      iex> OrdMap.keys([{"a", 2}, {"b", 3}])
      ["a", "b"]
      iex> OrdMap.keys([])
      []

  """
  @spec keys(t | tuples) :: [value]
  def keys(%OrdMap{tuples: tuples}), do: keys(tuples)
  def keys([]), do: []

  def keys([h | _] = tuples) when is_tuple(h) and tuple_size(h) == 2 do
    Enum.map(tuples, &elem(&1, 0))
  end

  @doc """
  Returns and removes the value associated with `key` in the `t:ord_map/0`.

  ## Examples

      iex> OrdMap.pop(o(%{"a" => 1}), "a")
      {1, o%{}}
      iex> OrdMap.pop(o(%{a: 1}), :b)
      {nil, o%{a: 1}}
      iex> OrdMap.pop(o(%{a: 1}), :b, 3)
      {3, o%{a: 1}}

  """
  @spec pop(t | tuples, key, default :: value) :: {value, t}
  def pop(term, key, default \\ nil)
  def pop(%OrdMap{tuples: tuples}, key, default), do: pop(tuples, key, default)
  def pop([], _key, default), do: {default, [] |> OrdMap.new()}

  def pop([h | _] = tuples, key, default) when is_tuple(h) and tuple_size(h) == 2 do
    case fetch(tuples, key) do
      {:ok, value} ->
        {value, delete(tuples, key) |> OrdMap.new()}

      :error ->
        {default, tuples |> OrdMap.new()}
    end
  end

  @doc """
  Puts the given `value` under `key`.

  If a previous value is already stored, the value is overridden.

  ## Examples

      iex> OrdMap.put(o(%{a: 1}), :b, 2)
      o%{a: 1, b: 2}
      iex> OrdMap.put(o(%{"a" => 1, b: 2}), "a", 3)
      o%{"a" => 3, b: 2}

  """
  @spec put(t | tuples, key, value) :: t
  def put(%OrdMap{tuples: tuples}, key, value), do: put(tuples, key, value)
  def put([], key, value), do: [{key, value}] |> OrdMap.new()

  def put([h | _] = tuples, key, value) when is_tuple(h) and tuple_size(h) == 2 do
    List.keystore(tuples, key, 0, {key, value}) |> OrdMap.new()
  end

  @doc """
  Alters the value stored under `key` to `value`, but only
  if the entry `key` already exists in `t:ord_map/0`.

  ## Examples

      iex> OrdMap.replace(o(%{a: 1}), :b, 2)
      o%{a: 1}
      iex> OrdMap.replace(o(%{a: 1, b: 2}), :a, 3)
      o%{a: 3, b: 2}
      iex> OrdMap.replace([{"c", 5},{"d", 6}], "c", 7)
      o%{"c" => 7, "d" => 6}
      iex> OrdMap.replace([], "c", 7)
      o%{}

  """
  @spec replace(t | tuples, key, value) :: t
  def replace(%OrdMap{tuples: tuples}, key, value), do: replace(tuples, key, value)
  def replace([], _key, _value), do: [] |> OrdMap.new()

  def replace([h | _] = tuples, key, value) when is_tuple(h) and tuple_size(h) == 2 do
    List.keyreplace(tuples, key, 0, {key, value}) |> OrdMap.new()
  end

  @doc """
  Returns all values from `t:ord_map/0`.

  ## Examples

      iex> OrdMap.values(o%{a: 1, b: 2})
      [1, 2]
      iex> OrdMap.values([a: 2, b: 3])
      [2, 3]
      iex> OrdMap.values([])
      []

  """
  @spec values(t | tuples) :: [value]
  def values(%OrdMap{tuples: tuples}) do
    values(tuples)
  end

  def values([]), do: []

  def values([h | _] = tuples) when is_tuple(h) and tuple_size(h) == 2 do
    Enum.map(tuples, &elem(&1, 1))
  end
end

defimpl Enumerable, for: OrdMap do
  alias Enumerable.List, as: EList

  def count(%OrdMap{tuples: tuples}), do: EList.count(tuples)
  def member?(%OrdMap{tuples: tuples}, element), do: EList.member?(tuples, element)
  def reduce(%OrdMap{tuples: tuples}, acc, fun), do: EList.reduce(tuples, acc, fun)
  def slice(%OrdMap{tuples: tuples}), do: EList.slice(tuples)
end
