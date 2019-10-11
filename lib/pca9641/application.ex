defmodule PCA9641.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: PCA9641.Worker.start_link(arg)
      # {PCA9641.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PCA9641.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
