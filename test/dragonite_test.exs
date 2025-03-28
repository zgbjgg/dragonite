defmodule DragoniteTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Dragonite.ParserCase

  setup do
    [
      generic_edi_transaction: ParserCase.fixture(:generic_edi_transaction),
      motor_load_tender_edi_transaction: ParserCase.fixture(:motor_load_tender_edi_transaction),
      valid_rules_edi_transaction: ParserCase.fixture(:valid_rules_edi_transaction),
      empty_edi_transaction: ParserCase.fixture(:empty_edi_transaction),
      only_isa_edi_transaction: ParserCase.fixture(:only_isa_edi_transaction),
      valid_edi_messages: ParserCase.fixture(:valid_edi_messages),
      integration_test_gs_values_ab: ParserCase.fixture(:integration_test_gs_values_ab),
      integration_test_gs_values_fa: ParserCase.fixture(:integration_test_gs_values_fa),
      integration_test_gs_values_gf: ParserCase.fixture(:integration_test_gs_values_gf),
      integration_test_gs_values_im: ParserCase.fixture(:integration_test_gs_values_im),
      integration_test_gs_values_qm: ParserCase.fixture(:integration_test_gs_values_qm),
      integration_test_gs_st_values: ParserCase.fixture(:integration_test_gs_st_values),
      integration_test_isa_gs_st_values: ParserCase.fixture(:integration_test_isa_gs_st_values)
    ]
    |> Enum.map(fn {k, str} -> {k, String.trim(str)} end)
  end

  describe "Parser decode" do
    @tag :parser_decode
    test "struct generic edi transaction", data do
      assert [{:ok, %DragoniteEDI.Message{}}] =
               Dragonite.Parser.decode(data.generic_edi_transaction)
    end

    @tag :parser_decode
    test "struct empty edi transaction", data do
      assert [{:error, {:unexpected_syntax_near_at, _}}] =
               Dragonite.Parser.decode(data.empty_edi_transaction)
    end

    @tag :parser_decode
    test "struct only isa on edi transaction", data do
      assert_raise ArgumentError, fn ->
        Dragonite.Parser.decode!(data.only_isa_edi_transaction)
      end
    end

    @tag :parser_decode
    test "parser decode valid_edi_messages", data do
      [{:ok, struct}] =
        data.valid_edi_messages
        |> Dragonite.Parser.decode()

      assert {:ok, %DragoniteEDI.Message{}} =
               struct
               |> Dragonite.Parser.is_valid(true)
    end
  end

  describe "Parser rules" do
    @tag :parser_rules
    test "rules on edi transaction", data do
      assert {:error, {:rules_not_passed, _}} =
               data.generic_edi_transaction
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on valid_edi_transaction", data do
      assert {:ok, %DragoniteEDI.Message{}} =
               data.valid_rules_edi_transaction
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on valid_edi_messages", data do
      assert {:ok, %DragoniteEDI.Message{}} =
               data.valid_edi_messages
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on integration_test_gs_values AB", data do
      assert {:error, {:rules_not_passed, [{"gs", [{1, "SM"}]}]}} =
               data.integration_test_gs_values_ab
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on integration_test_gs_values FA", data do
      assert {:error, {:rules_not_passed, [{"gs", [{1, "SM"}]}]}} =
               data.integration_test_gs_values_fa
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on integration_test_gs_values GF", data do
      assert {:error, {:rules_not_passed, [{"gs", [{1, "SM"}]}]}} =
               data.integration_test_gs_values_gf
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on integration_test_gs_values QM", data do
      assert {:error, {:rules_not_passed, [{"gs", [{1, "SM"}]}]}} =
               data.integration_test_gs_values_qm
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on integration_test_gs_st_values", data do
      assert {:error,
              {:rules_not_passed,
               [{"gs", [{1, "SM"}]}, {"st", [{2, [%{"el" => "se", "value" => 2}]}]}]}} =
               data.integration_test_gs_st_values
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "rules on integration_test_isa_gs_st_values", data do
      assert {
               :error,
               {
                 :rules_not_passed,
                 [
                   {"isa", [{6, [%{"el" => "gs", "value" => 2}]}]},
                   {"st", [{2, [%{"el" => "se", "value" => 2}]}]}
                 ]
               }
             } =
               data.integration_test_isa_gs_st_values
               |> Dragonite.Parser.decode!()
               |> Enum.at(0)
               |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])
    end

    @tag :parser_rules
    test "reload rules" do
      assert :ok == Dragonite.Config.reload()
    end

    @tag :parser_rules
    test "list all rules" do
      assert is_list(Dragonite.Config.rules())
    end
  end

  describe "Encode" do
    @tag :encode_struct
    test "encode structure valid", data do
      valid_edi = data.valid_edi_messages

      {_, struct_decode} =
        valid_edi
        |> Dragonite.Parser.decode!()
        |> Enum.at(0)
        |> Dragonite.Parser.to_rules(204, [%{qualifier: "08"}])

      assert struct_decode
             |> Dragonite.Parser.encode!()
    end

    @tag :encode_struct
    test "encode structure not verify", data do
      valid_edi = data.motor_load_tender_edi_transaction

      [{_, struct_decode}] =
        valid_edi
        |> Dragonite.Parser.decode(verify: false)

      assert struct_decode
             |> Dragonite.Parser.encode!()
    end

    @tag :encode_struct
    test "encode structure invalid" do
      assert_raise ArgumentError, fn ->
        Dragonite.Parser.encode!(%DragoniteEDI.Message{})
      end
    end
  end

  describe "Structs" do
    @tag :struct
    test "ISA struct", _data do
      isa_struct = %DragoniteEDI.ISA{}
      assert isa_struct.fields == []
    end

    @tag :struct
    test "IEA struct", _data do
      iea_struct = %DragoniteEDI.IEA{}
      assert iea_struct.fields == []
    end

    @tag :struct
    test "ST struct", _data do
      st_struct = %DragoniteEDI.ST{}
      assert st_struct.fields == []
    end

    @tag :struct
    test "SE struct", _data do
      se_struct = %DragoniteEDI.SE{}
      assert se_struct.fields == []
    end

    @tag :struct
    test "GS struct", _data do
      gs_struct = %DragoniteEDI.GS{}
      assert gs_struct.fields == []
    end

    @tag :struct
    test "GE struct", _data do
      ge_struct = %DragoniteEDI.GE{}
      assert ge_struct.fields == []
    end
  end

  describe "Seek" do
    @tag :seek
    test "struct at pos", data do
      [{:ok, struct}] =
        data.valid_edi_messages
        |> Dragonite.Parser.decode()

      [value | _] = Dragonite.Parser.struct_at(struct, "st", "$values")

      assert ["B2", "", "ABC", "", "1234567", "", "CC"] == value
    end

    @tag :seek
    test "seek for B2A", data do
      [{:ok, struct}] =
        data.valid_edi_messages
        |> Dragonite.Parser.decode()

      st_struct = Dragonite.Parser.struct_at(struct, "st", "$values")

      assert "00" ==
               Dragonite.Parser.seek(st_struct, [], [%{key: "B2A", pos: 1}], fn _, [value] ->
                 value
               end)
    end

    @tag :seek
    test "seek with condition", data do
      [{:ok, struct}] =
        data.valid_edi_messages
        |> Dragonite.Parser.decode()

      st_struct = Dragonite.Parser.struct_at(struct, "st", "$values")

      assert "92379702" ==
               Dragonite.Parser.seek(
                 st_struct,
                 [%{key: "L11", pos: 2, value: "P8"}],
                 [%{key: "L11", pos: 1, condition: %{pos: 2, value: "P8"}}],
                 fn _, [value] -> value end
               )
    end
  end
end
