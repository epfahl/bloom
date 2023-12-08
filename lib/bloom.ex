defmodule Bloom do
  defstruct [:n_bits, :n_hashes, :bits, :hash_fns]

  @type bit :: 0 | 1
  @type bit_array :: Arrays.array(bit)
  @type hash_fn :: (any -> binary)

  @type t :: %Bloom{
          n_bits: pos_integer,
          n_hashes: pos_integer,
          bits: bit_array,
          hash_fns: [hash_fn]
        }

  @type item :: any
  @type array_type :: :map | :erlang | :aja

  @spec new(number, number, keyword) :: t
  def new(capacity, fp_prob, opts \\ [])
      when capacity > 0 and
             fp_prob > 0 and
             fp_prob < 1 do
    array_type = Keyword.get(opts, :array_type, :map)
    {n_bits, n_hashes} = opt_params(capacity, fp_prob)

    %Bloom{
      n_bits: n_bits,
      n_hashes: n_hashes,
      bits: init_bits(n_bits, array_type),
      hash_fns: create_hash_fns(n_bits, n_hashes)
    }
  end

  @spec put(t, item) :: t
  def put(%Bloom{bits: bits, hash_fns: hash_fns} = bloom, item) do
    bits =
      Enum.reduce(hash_fns, bits, fn hash, acc ->
        set_bit(acc, hash.(item))
      end)

    %{bloom | bits: bits}
  end

  @spec member?(t, item) :: boolean
  def member?(%Bloom{bits: bits, hash_fns: hash_fns}, item) do
    do_member?(bits, hash_fns, item)
  end

  defp do_member?(_bits, [], _item), do: true

  defp do_member?(bits, [hash_fn | rest], item) do
    if get_bit(bits, hash_fn.(item)) == 1 do
      do_member?(bits, rest, item)
    else
      false
    end
  end

  @spec set_bit(bit_array, non_neg_integer) :: bit_array
  defp set_bit(bits, i), do: Arrays.replace(bits, i, 1)

  @spec get_bit(bit_array, non_neg_integer) :: bit
  defp get_bit(bits, i), do: Arrays.get(bits, i)

  @spec init_bits(pos_integer, array_type) :: bit_array
  defp init_bits(n_bits, array_type) do
    0..(n_bits - 1)
    |> Enum.map(fn _ -> 0 end)
    |> Arrays.new(implementation: impl(array_type))
  end

  @spec create_hash_fns(pos_integer, pos_integer) :: [hash_fn]
  def create_hash_fns(n_bits, n_hashes) do
    0..(n_hashes - 1)
    |> Enum.map(fn i ->
      fn item ->
        rem(
          Murmur.hash_x64_128(item, 123) + i * Murmur.hash_x64_128(item, 234),
          n_bits
        )
      end
    end)
  end

  @spec opt_params(number, number) :: {pos_integer, pos_integer}
  defp opt_params(capacity, fp_prob) do
    log_fp = :math.log2(fp_prob)
    {ceil(-1.4427 * capacity * log_fp), ceil(-log_fp)}
  end

  @spec impl(array_type) ::
          Arrays.Implementations.MapArray
          | Arrays.Implementations.MapArray
          | Aja.Vector
  def impl(:map), do: Arrays.Implementations.MapArray
  def impl(:erlang), do: Arrays.Implementations.ErlangArray
  def impl(:aja), do: Aja.Vector
end
