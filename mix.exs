defmodule Bloom.MixProject do
  use Mix.Project

  def project do
    [
      app: :bloom,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:arrays, "~> 2.1"},
      {:arrays_aja, "~> 0.2.0"},
      {:murmur, "~> 1.0"}
    ]
  end
end
