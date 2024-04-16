# Supabase GoTrue

[Auth](https://supabase.com/docs/guides/auth) implementation for the `supabase_potion` SDK in Elixir.

## Installation

```elixir
def deps do
  [
    {:supabase_potion, "~> 0.3"},
    {:supabase_gotrue, "~> 0.2"}
  ]
end
```

## Usage

Firstly you need to initialize your Supabase client(s) as can be found on the [supabase_potion documentation](https://hexdocs.pm/supabase_potion/Supabase.html#module-starting-a-client):

```elixir
iex> Supabase.init_client(%{name: Conn, conn: %{base_url: "<supa-url>", api_key: "<supa-key>"}})
{:ok, #PID<>}
```

Now you can pass the Client to the `Supabase.GoTrue` functions as a `PID` or the name that was registered on the client initialization:

```elixir
iex> Supabase.GoTrue.sign_in_with_password(pid | client_name, %{} = params)
```

This implementation also exposes an `Supaabse.GoTrue.Admin` function to interact with users with super powers:
```elixir
iex> Supabase.GoTrue.Admin.create_user(pid | client_name, %{} = params)
```
