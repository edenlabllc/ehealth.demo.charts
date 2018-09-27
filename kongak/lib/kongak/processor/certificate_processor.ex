defmodule Kongak.Processor.CertificateProcessor do
  @moduledoc false

  alias Kongak.Certificate
  alias Kongak.Config
  alias Kongak.Kong
  alias Kongak.Server

  def process(%Config{certificates: certificates}, %Server{} = server) do
    delete(server)
    create(certificates)
  end

  defp delete(%Server{certificates: certificates}) do
    Enum.map(certificates, &Kong.delete_certificate(Map.get(&1, "id")))
  end

  defp create(certificates) do
    Enum.map(certificates, &Kong.create/1)
  end
end
