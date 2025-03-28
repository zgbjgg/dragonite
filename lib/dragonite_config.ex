defmodule Dragonite.Config do
  @moduledoc """
  `Dragonite.Config` is used to handle the config for rules in a runtime environment
  allowing reload or get the rules.

  To configure the rules:

  ```
  config :dragonite, rules_file: "./rules.yml"
  ```

  The rules have a defined structure and must be placed into an available directory, please check
  priv directory to know how config for YML is used, the next is a single example of how
  YML structure works:

  ```
  - isa:
     04: "$edi_customer.edi_provider_id" ### ISA at position 04 MUST match with edi_provider_id value at database
     05: "08" ### ISA at position 05 MUST match 08 string.
     06:
         - {el: "gs", value: "02"} ### ISA at position 05 MUST have same value in GS at position 02
     15:
         - "P" ### ISA at position 15 MUST match P or T string, other value is not valid.
         - "T"
     16:
         - {el: "st", value: "$length"} ### ISA at position 16 should contains the length of ST elements, if ST elements are 6 this position MUST have 6.
  ```

  The above structure is translated to a single list and can be used to perform validations over
  an EDI message.

  The newly added wildcard with database works only with edi_customer reference, because this info collects
  from the parsing event and can be translated to rules.
  """
  use GenServer

  @doc """
  Returns the file config used for rules in the environment.
  """
  defmacro rules_file do
    quote do: Application.get_env(:dragonite, :rules_file)
  end

  @doc false
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @doc """
  Returns the rules already loaded.

  ## Example

      iex(1)> Dragonite.Config.rules()
  """
  @spec rules() :: list()
  def rules(), do: GenServer.call(__MODULE__, :rules)

  @doc """
  Returns the rules already loaded for a specific type.

  ## Example

      iex(1)> Dragonite.Config.rules(204)
  """
  @spec rules(integer()) :: list()
  def rules(for_type), do: GenServer.call(__MODULE__, {:rules, for_type})

  @doc """
  Reloads the rules file and store the new rules in runtime.

  ## Example

      iex(1)> Dragonite.Config.reload()
  """
  @spec reload() :: :ok
  def reload(), do: GenServer.cast(__MODULE__, :reload)

  @impl true
  def init([]), do: {:ok, load_rules_from_file()}

  @impl true
  def handle_call(:rules, _from, rules), do: {:reply, rules, rules}

  def handle_call({:rules, for_type}, _from, rules),
    do: {:reply, List.keyfind(rules, for_type, 0) |> elem(1), rules}

  @impl true
  def handle_cast(:reload, _state), do: {:noreply, load_rules_from_file()}

  defp load_rules_from_file() do
    rules_file()
    |> YamlElixir.read_from_file()
    |> case do
      {:ok, rules} ->
        rules
        |> Enum.map(fn rules_type ->
          [type] = Map.keys(rules_type)
          {type, Map.get(rules_type, type, [])}
        end)

      _ ->
        []
    end
  end
end
