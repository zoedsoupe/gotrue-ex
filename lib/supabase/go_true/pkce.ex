defmodule Supabase.GoTrue.PKCE do
  @moduledoc """
  This module is used to generate PKCE (Proof Key for Code Exchange) values.
  """

  @verifier_length 56

  def generate_verifier do
    @verifier_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
    |> String.slice(0, @verifier_length)
  end

  def generate_challenge(verifier) do
    :sha256
    |> :crypto.hash(verifier)
    |> Base.url_encode64(padding: false)
  end
end
