defmodule PCA9641.MixProject do
  use Mix.Project

  def project do
    [
      app: :pca9641,
      version: "0.2.2",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: "Driver for PCA9641 2-channel I2C bus master arbiter chip",
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {PCA9641.Application, []}
    ]
  end

  def package do
    [
      maintainers: ["James Harton <james@automat.nz>"],
      licenses: ["MIT"],
      links: %{
        "Source" => "https://gitlab.com/jimsy/pca9641"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_ale, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
