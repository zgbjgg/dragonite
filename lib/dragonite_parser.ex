defmodule Dragonite.Parser do
  @moduledoc """
  `Dragonite.Parser` is the module to handle decode and encode for an EDI
  message.

  ## Decoding

  To decode a message, use the `decode/1` function, providing a string as argument. The decode function
  tries to decode the message into an `%DragoniteEDI.Message{}` struct and raises an error if the message provided
  is not a valid message. To decode the parser follow the next rules:

  * Must start with ISA struct.

  * Must end with IEA struct.

  * Function groups start with GS and end with GE.

  * Segments start with ST and end with SE.

  * Separator for elements is `~`

  * Separator for elements into fields is `*`

  This is a single example of an EDI message:

  ```
  iex(1)> msg = "ISA*00* *00* *32*0000*32*0000 *121206*1142*U*00601*000000003*1*T*>~" <>
  "GS*SM*300237446*351538247*20121206*1142*3*X*006010~ST*204*000000001~B2**BWEM**317749**CC*L~" <>
  "B2A*00*FR~L11*SMC LTL Fuel*XX7*Fuel Schedule: SMC LTL Fuel~L11*104*ZZ*Total Distance:104~G6" <>
  "2*64*20121206*1*1244*LT~AT5*400**Transport~RTT*FC*550~C3*USD~N1*BT*Pokemon GO*93*2649" <>
  "~N3*19661 Brownstown Center Dr*Suite 600~N4*Brownstown*MI*48183-1679*USA~G61*LG*Contact Phone" <>
  "*TE*000-000-000 ext 3~G61*LG*Contact Mobile*CP*000-000-0000~G61*LG*Contact Email*EM*" <>
  "dratini@pokemon.com~N7**Unknown*********53****0636*****110*98~S5*0*LD~L11*602465*SI~" <>
  "G62*69*20120810*U*1600*LT~N1*SH*POKEMON GO*93*5715~N3*603 7th St~N4*Pokemon*MI*49601-1344*" <>
  "USA~G61*LG*Contact Phone*TE*000-000-0000 ext 1357~G61*LG*Contact Email*EM*dratini@pokemon.com" <>
  "~N1*CN*ABC Undercar Products Group*93*9889~N3*4247 Paleta Town SE~N4*Wyoming*MI*49508-3400*USA~N1*" <>
  "SF*AVON AUTOMOTIVE*93*5715~N3*603 7th St~N4*Pokemon*MI*49601-1344*USA~G61*LG*Contact Phone*TE*" <>
  "000-000-0000 ext 1357~G61*LG*Contact Email*EM*dratini@pokemon.com~LAD*PLT****L**S1*264" <>
  "*****Freight All Kinds~L5*1**60*N~S5*1*UL~L11*602465*SI~G62*69*20120813*U*1600*LT~N1*SH*POKEMON" <>
  " GO*93*5715~N3*603 7th St~N4*Pokemon*MI*49601-1344*USA~G61*LG*Contact Phone*TE*000-000" <>
  "-0000 ext 1357~G61*LG*Contact Email*EM*dratini@pokemon.com~N1*CN*ABC " <>
  "Products Group*93*9889~N3*4247 Paleta Town SE~N4*Wyoming*MI*49508-3400*USA~N1*ST*ABC " <>
  " Products Group*93*9889~N3*4247 Paleta Town SE~N4*Wyoming*MI*49508-3400*USA~LAD*PLT" <>
  "****L**S1*264*****Freight All Kinds~L5*1**60*N~SE*51*000000001~GE*1*3~IEA*1*000000003"
  ```

  Now to decode the above message just call to `decode/1`:

  ```
  iex(2)> Dragonite.Parser.decode msg
  ```

  The response (if valid) will be an `%DragoniteEDI.Message{}` struct containing all elements considered from parsing
  rules. New rules can de added if nedeed.

  ## Decoding multiple STs

  Sometimes the incoming messages will contain multiple ST, this means that multiple messages are sent once a time.

  To support this, the decode/1 returns a list of messages instead a single response (even if only 1).

  ## Encoding

  To encode a message use the `encode/1` function, providing a `DragoniteEDI.Message{}` as argument. The encode function
  tries to encode the struct as a string message and raises an errir if the message provided is not a valid message. To encode
  a message:

  ```
  iex(1)> Dragonite.Parser.encode %DragoniteEDI.Message{}
  ```

  The response is a single string as an original EDI message.

  ## Verification

  By default `decode/1` verifies the struct and return `{:ok, %DragoniteEDI.Message{}}` or `{:error, error}` where
  error will describe the missing or incomplete struct. Missing or incomplete structs are marked when sub-structs
  are nil or empty lists.

  Validation can be skipped using `verify: false` when calling `decode/2` using opts (2nd argument) as keywords.

  By default `encode/1` verifies the struct of edi message, this is mandatory.

  ## Rules

  A single message can be passed (after parsed) for a set of rules to check if passed the criteria
  or not.

  The rules criteria are defined in a single YML file (see Config for more info).

  To check if a message pass the criteria:

  ```
  iex(1)> Dragonite.Parser.to_rules %DragoniteEDI.Message{}, 204
  ```

  If passed the struct is returned, otherwise an error is returned.

  ## Seek

  Seek allows search in values of ST segment, match criteria and return values based on custom functions
  provided as a part of seek process. Seek process needs the values (that can be extracted using `struct_at/3`),
  the matching criteria, the values to return and a fn with two args, the first one is the resulting of matching
  criteria and the second one the return data.
  """
  alias DragoniteEDI.{Message, ISA, IEA, GS, GE, ST, SE}
  alias Dragonite.Config

  @sep "~"

  @sep_el "*"

  @doc """
  Tries to decode a single EDI message from a string into `%DragoniteEDI.Message{}`. Raises an
  argument error if message provided is not a valid message with the struct of EDI protocol.

  ## Example

      iex(1)> Dragonite.Parser.decode "ISA..."
  """
  @spec decode(String.t()) :: list({:ok, %DragoniteEDI.Message{}}) | list({:error, atom()})
  def decode(msg, opts \\ [verify: true])

  def decode(msg, verify: should_verify) do
    {sts, %{base_segments: base_segments}} =
      msg
      |> String.split(@sep)
      |> Enum.map_reduce(%{in_st: false, base_segments: []}, &handle_multiple_st/2)

    messages =
      sts
      |> Enum.reduce(
        %{in_st: false, st_acc: [], messages: [], base_segments: base_segments},
        &mix_segments/2
      )
      |> Map.get(:messages, [])
      |> case do
        [] ->
          [base_segments]

        messages ->
          messages
      end

    messages
    |> Enum.map(&process_messages(&1, should_verify: should_verify, sts_length: length(messages)))
  end

  @doc """
  Same as `decode/1` but raises an error instead of return the error message.

  ## Example

      iex(1)> Dragonite.Parse.decode! "ISA..."
  """
  @spec decode!(String.t()) :: list(%DragoniteEDI.Message{}) | no_return()
  def decode!(msg, opts \\ [verify: true])

  def decode!(msg, opts) do
    structs = decode(msg, opts)

    structs
    |> Enum.find(&Kernel.==(elem(&1, 0), :error))
    |> case do
      nil ->
        Enum.map(structs, &elem(&1, 1))

      error ->
        raise(ArgumentError,
          message: "error when parsing message: #{inspect(error)}"
        )
    end
  end

  @doc """
  Tries to encode a single EDI message from struct into string. Raises an argument error
  if message provided is not a valid message with the struct of EDI protocol.

  ## Example

      iex(1)> Dragonite.Parser.encode %DragoniteEDI.Message{}
  """
  @spec encode(%DragoniteEDI.Message{}) :: {:ok, String.t()} | {:error, atom()}
  def encode(struct) do
    struct
    |> is_valid(true)
    |> case do
      {:ok, struct} ->
        do_encode(struct)
        |> Enum.map(&Enum.join(&1, @sep_el))
        |> Enum.join(@sep)
        |> Kernel.<>(@sep)
        |> (&{:ok, &1}).()

      error ->
        error
    end
  end

  @doc """
  Same as `encode/1` but raises an error instead of return the error message.

  ## Example

      iex(1)> Dragonite.Parser.encode! %DragoniteEDI.Message{}
  """
  @spec encode!(%DragoniteEDI.Message{}) :: String.t() | no_return()
  def encode!(struct) do
    case encode(struct) do
      {:error, error} ->
        raise(ArgumentError,
          message: "error when parsing struct: #{inspect(error)}"
        )

      {:ok, msg_str} ->
        msg_str
    end
  end

  @doc """
  Verifies if a `DragoniteEDI.Message{}` is valid, checking if all sub-structs are non empty and then
  mark message as valid. Return error at sub-struct incompleted.

  A custom check can be passed to skip the validation in order to use in some pipelines.

  ## Example

      iex(1)> Dragonite.Parser.is_valid(%DragoniteEDI.Message{})
  """
  @spec is_valid(%DragoniteEDI.Message{}, true | false) ::
          {:ok, %DragoniteEDI.Message{}} | {:error, atom()}
  def is_valid(struct, check \\ true)
  def is_valid({:error, _} = error, false), do: error
  def is_valid(struct, false), do: {:ok, struct}
  def is_valid(%DragoniteEDI.Message{isa: nil}, true), do: {:error, :isa_empty}
  def is_valid(%DragoniteEDI.Message{iea: nil}, true), do: {:error, :iea_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{fields: []}}, true),
    do: {:error, :isa_fields_empty}

  def is_valid(%DragoniteEDI.Message{iea: %IEA{fields: []}}, true),
    do: {:error, :iea_fields_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{gs: nil}}, true), do: {:error, :gs_empty}
  def is_valid(%DragoniteEDI.Message{isa: %ISA{ge: nil}}, true), do: {:error, :ge_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{gs: [%GS{fields: []}]}}, true),
    do: {:error, :gs_fields_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{gs: [%GS{se: nil}]}}, true),
    do: {:error, :se_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{gs: [%GS{st: nil}]}}, true),
    do: {:error, :st_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{gs: [%GS{st: [%ST{fields: []}]}]}}, true),
    do: {:error, :st_fields_empty}

  def is_valid(%DragoniteEDI.Message{isa: %ISA{gs: [%GS{st: [%ST{values: []}]}]}}, true),
    do: {:error, :st_values_empty}

  def is_valid({:error, _} = error, true), do: error

  def is_valid(struct, true), do: {:ok, struct}

  @doc """
  Check if a `%DragoniteEDI.Message{}` is valid against rules defined in environment, so
  don't need to pass rules, since they are loaded from pre-loaded config.

  If rules are empty the message is marked as valid, since there are no rules to check.

  The function returns either the message or an error containing the validation that breaks the rules.

  To work with wildcards just pass the wildcard as an enumerable of one struct:

  ```
  Dragonite.Parser.to_rules(%DragoniteEDI.Message{}, 204, [%MyStruct{qualifier: "Q1"}])
  ```

  After that definitions in YML against `$custom.?` will run extracting the value
  from custom struct provided.

  ## Example

      iex(1)> Dragonite.Parser.to_rules(%DragoniteEDI.Message{}, 204)
  """
  @spec to_rules(%DragoniteEDI.Message{}, integer(), list(String.t())) ::
          {:ok, %DragoniteEDI.Message{}} | {:error, {:rules_not_passed, list()}}
  def to_rules(struct, for_type, wildcards \\ []) do
    Config.rules(for_type)
    |> Enum.map(fn rule ->
      [el] = Map.keys(rule)

      not_passed =
        Map.get(rule, el, %{})
        |> Enum.filter(&(!check_rule(&1, el, struct, wildcards)))

      {el, not_passed}
    end)
    |> Enum.filter(fn
      {_, []} -> false
      _ -> true
    end)
    |> case do
      [] -> {:ok, struct}
      rules -> {:error, {:rules_not_passed, rules}}
    end
  end

  @doc """
  Get value at position, length or full values of some segment in Edi message struct

  ## Example

      iex(1)> Dragonite.Parser.struct_at(%DragoniteEDI.Message{}, "isa", 1)
  """
  @spec struct_at(%DragoniteEDI.Message{}, String.t(), any()) ::
          String.t() | list() | non_neg_integer()
  def struct_at(struct, "gs", "$length"), do: struct.isa.gs |> Kernel.length()

  def struct_at(struct, "st", "$length"),
    do: struct.isa.gs |> Enum.at(0) |> Map.get(:st, []) |> Kernel.length()

  def struct_at(struct, "st", "$values"),
    do: struct.isa.gs |> Enum.at(0) |> Map.get(:st, []) |> Enum.at(0) |> Map.get(:values, [])

  def struct_at(struct, "isa", position), do: struct.isa.fields |> Enum.at(position)
  def struct_at(struct, "iea", position), do: struct.iea.fields |> Enum.at(position)
  def struct_at(struct, "ge", position), do: struct.isa.ge.fields |> Enum.at(position)

  def struct_at(struct, "gs", position),
    do: struct.isa.gs |> Enum.at(0) |> Map.get(:fields, []) |> Enum.at(position)

  def struct_at(struct, "se", position),
    do:
      struct.isa.gs
      |> Enum.at(0)
      |> Map.get(:se, %{})
      |> Map.get(:fields, [])
      |> Enum.at(position)

  def struct_at(struct, "st", position),
    do:
      struct.isa.gs
      |> Enum.at(0)
      |> Map.get(:st, [])
      |> Enum.at(0)
      |> Map.get(:fields, [])
      |> Enum.at(position)

  @doc """
  Seek criteria and apply fun to elements found

  ## Example

      iex(1)> Dragonite.Parser.seek([["L11", "", ""]], [], [%{key: "L11", pos: 1}], fn _, _ -> :ok end)
  """
  @spec seek([list()], list(), [list()], (list(), [list()] -> binary | number())) ::
          binary | number()
  def seek(values, condition, extractor, fun) do
    values_condition =
      condition
      |> Enum.map(&complete(&1, values))
      |> Enum.map(&Enum.uniq/1)
      |> Enum.flat_map(& &1)

    values_extractor =
      extractor
      |> Enum.map(&complete(&1, values))

    fun.(values_condition, values_extractor)
  end

  defp decode([], struct, _), do: struct

  defp decode([["ISA" | isa_fields] | elements], %Message{isa: nil} = struct, :transaction) do
    decode(elements, Map.put(struct, :isa, %ISA{fields: isa_fields, gs: nil}), :func_group)
  end

  defp decode([["IEA" | iea_fields] | elements], %Message{iea: nil} = struct, :transaction) do
    decode(elements, Map.put(struct, :iea, %IEA{fields: iea_fields}), :transaction)
  end

  defp decode(
         [["GS" | gs_fields] | elements],
         %Message{isa: %ISA{fields: _isa_fields, gs: nil} = isa} = struct,
         :func_group
       ) do
    new_isa = Map.put(isa, :gs, [%GS{fields: gs_fields, st: nil}])
    decode(elements, Map.put(struct, :isa, new_isa), :segment)
  end

  defp decode(
         [["GS" | gs_fields] | elements],
         %Message{isa: %ISA{fields: _isa_fields, gs: gs} = isa} = struct,
         :func_group
       ) do
    new_isa = Map.put(isa, :gs, gs ++ [%GS{fields: gs_fields, st: nil}])
    decode(elements, Map.put(struct, :isa, new_isa), :segment)
  end

  defp decode(
         [["GE" | ge_fields] | elements],
         %Message{isa: %ISA{fields: _isa_fields, gs: _gs} = isa} = struct,
         :func_group
       ) do
    new_isa = Map.put(isa, :ge, %GE{fields: ge_fields})
    decode(elements, Map.put(struct, :isa, new_isa), :transaction)
  end

  defp decode(
         [["ST" | st_fields] | elements],
         %Message{
           isa: %ISA{fields: _isa_fields, gs: [%GS{fields: _gs_fields, st: nil} = gs]} = isa
         } = struct,
         :segment
       ) do
    new_gs = Map.put(gs, :st, [%ST{fields: st_fields, values: []}])
    new_isa = Map.put(isa, :gs, [new_gs])
    decode(elements, Map.put(struct, :isa, new_isa), :segment)
  end

  defp decode(
         [["ST" | st_fields] | elements],
         %Message{
           isa: %ISA{fields: _isa_fields, gs: [%GS{fields: _gs_fields, st: st} = gs]} = isa
         } = struct,
         :segment
       ) do
    new_gs = Map.put(gs, :st, st ++ [%ST{fields: st_fields, values: []}])
    new_isa = Map.put(isa, :gs, [new_gs])
    decode(elements, Map.put(struct, :isa, new_isa), :segment)
  end

  defp decode(
         [["SE" | se_fields] | elements],
         %Message{isa: %ISA{fields: _isa_fields, gs: [%GS{fields: _gs_fields} = gs]} = isa} =
           struct,
         :segment
       ) do
    new_gs = Map.put(gs, :se, %SE{fields: se_fields})
    new_isa = Map.put(isa, :gs, [new_gs])
    decode(elements, Map.put(struct, :isa, new_isa), :func_group)
  end

  defp decode(
         [fields | elements],
         %Message{
           isa:
             %ISA{
               fields: _isa_fields,
               gs: [
                 %GS{fields: _gs_fields, st: [%ST{fields: _st_fields, values: values} = st]} = gs
               ]
             } = isa
         } = struct,
         :segment
       ) do
    new_st = Map.put(st, :values, values ++ [fields])
    new_gs = Map.put(gs, :st, [new_st])
    new_isa = Map.put(isa, :gs, [new_gs])
    decode(elements, Map.put(struct, :isa, new_isa), :segment)
  end

  defp decode([[""] | elements], struct, flag), do: decode(elements, struct, flag)

  defp decode(element, _, _), do: {:error, {:unexpected_syntax_near_at, Enum.join(element, "*")}}

  defp check_rule({position, "$custom." <> field}, el, struct, [wildcard])
       when is_integer(position) do
    value = Map.get(wildcard, String.to_atom(field), "")

    struct
    |> struct_at(el, position - 1)
    |> String.trim()
    |> Kernel.==(value)
  end

  defp check_rule({position, value}, el, struct, _wildcard)
       when is_binary(value) and is_integer(position) do
    struct
    |> struct_at(el, position - 1)
    |> Kernel.==(value)
  end

  defp check_rule(
         {position, [%{"el" => sub_el, "value" => "$values"}]},
         el,
         struct,
         _wildcard
       )
       when is_integer(position) do
    value =
      struct
      |> struct_at(el, position - 1)
      |> String.to_integer()

    sub_value =
      struct
      |> struct_at(sub_el, "$values")
      |> Kernel.length()
      |> Kernel.+(2)

    sub_value == value
  end

  defp check_rule(
         {position, [%{"el" => "st", "value" => "$length"}]},
         el,
         %DragoniteEDI.Message{sts: 1} = struct,
         _wildcard
       )
       when is_integer(position) do
    value =
      struct
      |> struct_at(el, position - 1)
      |> String.to_integer()

    sub_value = struct_at(struct, "st", "$length")
    sub_value == value
  end

  defp check_rule(
         {position, [%{"el" => "st", "value" => "$length"}]},
         el,
         %DragoniteEDI.Message{sts: length} = struct,
         _wildcard
       )
       when is_integer(position) and length > 1 do
    struct
    |> struct_at(el, position - 1)
    |> String.to_integer()
    |> Kernel.==(length)
  end

  defp check_rule(
         {position, [%{"el" => sub_el, "value" => "$length"}]},
         el,
         struct,
         _wildcard
       )
       when is_integer(position) do
    value =
      struct
      |> struct_at(el, position - 1)
      |> String.to_integer()

    sub_value = struct_at(struct, sub_el, "$length")
    sub_value == value
  end

  defp check_rule(
         {position, [%{"el" => sub_el, "value" => sub_position}]},
         el,
         struct,
         _wildcard
       )
       when is_integer(sub_position) and is_integer(position) do
    value =
      struct
      |> struct_at(el, position - 1)
      |> String.trim()

    sub_value = struct_at(struct, sub_el, sub_position - 1)
    value == sub_value
  end

  defp check_rule(
         {"na", [%{"el" => sub_el, "value" => value, "cond" => cond, "agg" => "$count"}]},
         el,
         struct,
         _wildcard
       ) do
    sub_el_count =
      struct
      |> struct_at(el, "$values")
      |> Enum.count(&(Enum.at(&1, 0) == sub_el))

    apply(Kernel, String.to_atom(cond), [sub_el_count, value])
  end

  defp check_rule(
         {position, ["$custom." <> _field = wildcard | rest]},
         el,
         struct,
         [_] = wildcard_struct
       )
       when is_integer(position) do
    {position, wildcard}
    |> check_rule(el, struct, wildcard_struct)
    |> Kernel.and(check_rule({position, rest}, el, struct, wildcard_struct))
  end

  defp check_rule({position, value}, el, struct, _wildcard)
       when is_list(value) and is_integer(position) do
    el_value = struct_at(struct, el, position - 1)
    Enum.member?(value, el_value)
  end

  defp check_rule(_, _el, _struct, _wildcard), do: false

  defp do_encode(%DragoniteEDI.Message{isa: isa, iea: iea}), do: do_encode(isa) ++ do_encode(iea)

  defp do_encode(%DragoniteEDI.ISA{fields: fields, gs: gs, ge: ge}),
    do: [["ISA"] ++ fields] ++ do_encode(gs) ++ do_encode(ge)

  defp do_encode(%DragoniteEDI.IEA{fields: fields}), do: [["IEA"] ++ fields]

  defp do_encode([%DragoniteEDI.GS{fields: fields, st: st, se: se}]),
    do: [["GS"] ++ fields] ++ do_encode(st) ++ do_encode(se)

  defp do_encode(%DragoniteEDI.GE{fields: fields}), do: [["GE"] ++ fields]

  defp do_encode([%DragoniteEDI.ST{fields: fields, values: values}]),
    do: [["ST"] ++ fields] ++ values

  defp do_encode(%DragoniteEDI.SE{fields: fields}), do: [["SE"] ++ fields]

  defp complete(%{key: k, pos: pos, condition: []}, values) do
    Enum.find(values, [], fn [key | _] -> key == k end)
    |> Enum.at(pos, "")
  end

  defp complete(
         %{
           key: k,
           pos: pos,
           condition: [%{pos: pos_comparison, value: comparison, key: key} | conditions]
         },
         values
       ) do
    complete(
      %{key: k, pos: pos, condition: conditions},
      loop(values, pos_comparison, key, comparison)
    )
  end

  defp complete(
         %{key: k, pos: pos, condition: %{pos: pos_comparison, value: comparison} = condition},
         values
       ) do
    case Map.get(condition, :key) do
      nil ->
        Enum.find(values, [], &do_comparison(&1, pos_comparison, k, comparison))
        |> Enum.at(pos, "")

      key_cond ->
        loop(values, pos_comparison, key_cond, comparison)
        |> Enum.find([], fn [key | _] -> key == k end)
        |> Enum.at(pos, "")
    end
  end

  defp complete(%{key: k, pos: pos, value: comparison}, values) do
    Enum.filter(values, &do_comparison(&1, pos, k, comparison))
    |> Enum.map(fn elems -> Enum.at(elems, pos, "") end)
  end

  defp complete(%{key: k, pos: pos}, values) do
    Enum.find(values, [], fn [key | _] -> key == k end)
    |> Enum.at(pos, "")
  end

  defp do_comparison([key | _] = rest, pos, key, comparison) when is_binary(comparison) do
    Enum.at(rest, pos, "") == comparison
  end

  defp do_comparison([key | _] = rest, pos, key, comparison) when is_list(comparison) do
    Enum.at(rest, pos, "") in comparison
  end

  defp do_comparison(_segment, _pos, _key, _comparison), do: false

  defp loop([], _pos, _key, _comparison), do: []

  defp loop([[key | _] = rest | segments], pos, key, comparison) when is_binary(comparison) do
    case Enum.at(rest, pos, "") == comparison do
      true ->
        segments =
          Enum.reduce_while(segments, [], fn
            [s_key | _], acc when s_key == key -> {:halt, acc}
            value, acc -> {:cont, acc ++ [value]}
          end)

        [rest] ++ segments

      false ->
        loop(segments, pos, key, comparison)
    end
  end

  defp loop([_ | segments], pos, key, comparison) when is_binary(comparison) do
    loop(segments, pos, key, comparison)
  end

  defp handle_multiple_st("ST" <> _st_fields = st, %{in_st: false, base_segments: base_segments}) do
    {st, %{in_st: true, base_segments: base_segments}}
  end

  defp handle_multiple_st("SE" <> _se_fields = se, %{in_st: true, base_segments: base_segments}) do
    {se, %{in_st: false, base_segments: base_segments}}
  end

  defp handle_multiple_st(segment, %{in_st: true, base_segments: base_segments}) do
    {segment, %{in_st: true, base_segments: base_segments}}
  end

  defp handle_multiple_st(segment, %{in_st: false, base_segments: base_segments}) do
    {nil, %{in_st: false, base_segments: base_segments ++ [segment]}}
  end

  defp handle_multiple_st(_segment, acc), do: {nil, acc}

  defp mix_segments(nil, messages), do: messages

  defp mix_segments("ST" <> _st_fields = st, %{
         in_st: false,
         st_acc: st_acc,
         messages: messages,
         base_segments: base_segments
       }) do
    %{in_st: true, st_acc: st_acc ++ [st], messages: messages, base_segments: base_segments}
  end

  defp mix_segments("SE" <> _se_fields = se, %{
         in_st: true,
         st_acc: st_acc,
         messages: messages,
         base_segments: base_segments
       }) do
    # we need put st before GE
    messages =
      messages ++
        [
          Enum.reduce(base_segments, %{st: st_acc ++ [se], message: []}, &st_before_ge/2)
          |> Map.get(:message)
        ]

    %{in_st: false, st_acc: [], messages: messages, base_segments: base_segments}
  end

  defp mix_segments(segment, %{
         in_st: true,
         st_acc: st_acc,
         messages: messages,
         base_segments: base_segments
       }) do
    %{in_st: true, st_acc: st_acc ++ [segment], messages: messages, base_segments: base_segments}
  end

  defp mix_segments(_segment, messages), do: messages

  defp st_before_ge("GE" <> _ge_fields = segment, %{st: st, message: message}),
    do: %{st: st, message: message ++ st ++ [segment]}

  defp st_before_ge(segment, %{st: st, message: message}),
    do: %{st: st, message: message ++ [segment]}

  defp process_messages(message, should_verify: should_verify, sts_length: sts_length) do
    message
    |> Enum.map(&String.split(&1, @sep_el))
    |> decode(%Message{isa: nil, iea: nil, sts: sts_length}, :transaction)
    |> is_valid(should_verify)
  end
end
