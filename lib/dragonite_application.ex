defmodule Dragonite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    children = [
      # Start the Config rules server
      {Dragonite.Config, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fr8hubEdi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
