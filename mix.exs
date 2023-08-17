defmodule SilverOrb.MixProject do
  use Mix.Project

  def project do
    [
      app: :silver_orb,
      version: "0.0.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:orb, "~> 0.0.13"},
      {:orb_wasmtime, "~> 0.1.10", only: :test}
    ]
  end
end
