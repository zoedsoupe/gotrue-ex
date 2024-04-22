defmodule SupabaseAuth.MixProject do
  use Mix.Project

  @version "0.3.3"
  @source_url "https://github.com/zoedsoupe/gotrue-ex"

  def project do
    [
      app: :supabase_gotrue,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      description: description()
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
      {:plug, "~> 1.15"},
      {:supabase_potion, "~> 0.3"},
      {:phoenix_live_view, "~> 0.20"},
      {:ex_doc, ">= 0.0.0", runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      contributors: ["zoedsoupe"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/supabase_auth"
      },
      files: ~w[lib mix.exs README.md LICENSE]
    }
  end

  defp docs do
    [
      main: "Supabase.GoTrue",
      extras: ["README.md"]
    ]
  end

  defp description do
    """
    Integration with the GoTrue API from Supabase services.
    Provide authentication with MFA, password and magic link.
    """
  end
end
