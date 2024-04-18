defmodule Supabase.GoTrue.Schemas.AdminUserParams do
  @moduledoc """
  Admin user params schema. This schema is used to validate and parse the parameters for creating a new admin user.

  ## Fields
    * `app_metadata` - The metadata to associate with the user.
    * `email_confirm` - Whether the user's email is confirmed.
    * `phone_confirm` - Whether the user's phone is confirmed.
    * `ban_duration` - The duration of the user's ban.
    * `role` - The user's role.
    * `email` - The user's email.
    * `phone` - The user's phone.
    * `password` - The user's password.
    * `nonce` - The user's nonce.
  """

  import Ecto.Changeset
  import Supabase.GoTrue.Validations

  @types %{
    app_metadata: :map,
    email_confirm: :boolean,
    phone_confirm: :boolean,
    ban_duration: :string,
    role: :string,
    email: :string,
    phone: :string,
    password: :string,
    nonce: :string
  }

  def parse(attrs) do
    {%{}, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_required_inclusion([:email, :phone])
    |> apply_action(:parse)
  end

  def parse_update(attrs) do
    {%{}, @types}
    |> cast(attrs, Map.keys(@types))
    |> apply_action(:parse)
  end
end
