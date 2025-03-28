defmodule Dragonite.ParserCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  def fixture(:generic_edi_transaction) do
    File.read!("test/edi_messages/generic.edi")
  end

  def fixture(:valid_rules_edi_transaction) do
    File.read!("test/edi_messages/valid_rules_transaction.edi")
  end

  def fixture(:valid_edi_messages) do
    File.read!("test/edi_messages/valid.edi")
  end

  # 204 edi transaction
  def fixture(:motor_load_tender_edi_transaction) do
    File.read!("test/edi_messages/valid_motor_load_tender.edi")
  end

  def fixture(:empty_edi_transaction) do
    "ISA*00* *00* *32*300237446*32*351538247 *121206*1142*U*00601*000000003*1*T*>~IEA*1*000000003~"
  end

  def fixture(:only_isa_edi_transaction) do
    "ISA*00* *00* *32*300237446*32*351538247 *121206*1142*U*00601*000000003*1*T*>"
  end

  def fixture(:integration_test_gs_values_ab) do
    File.read!("test/edi_messages/test_gs_values_ab.edi")
  end

  def fixture(:integration_test_gs_values_fa) do
    File.read!("test/edi_messages/test_gs_values_fa.edi")
  end

  def fixture(:integration_test_gs_values_gf) do
    File.read!("test/edi_messages/test_gs_values_gf.edi")
  end

  def fixture(:integration_test_gs_values_im) do
    File.read!("test/edi_messages/test_gs_values_im.edi")
  end

  def fixture(:integration_test_gs_values_qm) do
    File.read!("test/edi_messages/test_gs_values_qm.edi")
  end

  def fixture(:integration_test_gs_st_values) do
    File.read!("test/edi_messages/test_gs_st_values.edi")
  end

  def fixture(:integration_test_isa_gs_st_values) do
    File.read!("test/edi_messages/test_isa_gs_st_values.edi")
  end
end
