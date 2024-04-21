defmodule Supabase.GoTrue do
  @moduledoc """
  This module provides the functionality to interact with the GoTrue API,
  allowing management of users, sessions, and authentication.

  It also aims to provide integrations with Plug and Phoenix LiveView applications.

  For detailed information about the GoTrue API, check the official documentation at https://supabase.io/docs/reference/javascript/auth-api

  And also refer to functions and submodules documentation for more information.
  """

  import Supabase.Client, only: [is_client: 1]

  alias Supabase.Client
  alias Supabase.GoTrue.Schemas.SignInWithIdToken
  alias Supabase.GoTrue.Schemas.SignInWithOauth
  alias Supabase.GoTrue.Schemas.SignInWithOTP
  alias Supabase.GoTrue.Schemas.SignInWithPassword
  alias Supabase.GoTrue.Schemas.SignInWithSSO
  alias Supabase.GoTrue.Schemas.SignUpWithPassword
  alias Supabase.GoTrue.Session
  alias Supabase.GoTrue.User
  alias Supabase.GoTrue.UserHandler

  @opaque client :: pid | module

  @behaviour Supabase.GoTrueBehaviour

  @doc """
  Get the user associated with the current session.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `session` - The session to use for the request. Check `Supabase.GoTrue.Session` for more information.

  ## Examples
      iex> session = %Supabase.GoTrue.Session{access_token: "example_token"}
      iex> Supabase.GoTrue.get_user(pid | client_name, session)
      {:ok, %Supabase.GoTrue.User{}}
  """
  @impl true
  def get_user(client, %Session{} = session) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, response} <- UserHandler.get_user(client, session.access_token) do
      User.parse(response)
    end
  end

  @doc """
  Signs in a user with ID token.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `credentials` - The credentials to use for the sign in. Check `Supabase.GoTrue.Schemas.SignInWithIdToken` for more information.

  ## Examples
      iex> credentials = %Supabase.GoTrue.SignInWithIdToken{}
      iex> Supabase.GoTrue.sign_in_with_id_token(pid | client_name, credentials)
      {:ok, %Supabase.GoTrue.User{}}
  """
  @impl true
  def sign_in_with_id_token(client, credentials) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, credentials} <- SignInWithIdToken.parse(credentials) do
      UserHandler.sign_in_with_id_token(client, credentials)
    end
  end

  @doc """
  Signs in a user with OAuth.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `credentials` - The credentials to use for the sign in. Check `Supabase.GoTrue.Schemas.SignInWithOauth` for more information.

  ## Examples
      iex> credentials = %Supabase.GoTrue.SignInWithOauth{}
      iex> Supabase.GoTrue.sign_in_with_oauth(pid | client_name, credentials)
      {:ok, atom, URI.t()}
  """
  @impl true
  def sign_in_with_oauth(client, credentials) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, credentials} <- SignInWithOauth.parse(credentials) do
      url = UserHandler.get_url_for_provider(client, credentials)
      {:ok, credentials.provider, url}
    end
  end

  @doc """
  Signs in a user with OTP.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `credentials` - The credentials to use for the sign in. Check `Supabase.GoTrue.Schemas.SignInWithOTP` for more information.

  ## Examples
      iex> credentials = %Supabase.GoTrue.SignInWithOTP{}
      iex> Supabase.GoTrue.sign_in_with_otp(pid | client_name, credentials)
      {:ok, %Supabase.GoTrue.Session{}}
  """
  @impl true
  def sign_in_with_otp(client, credentials) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, credentials} <- SignInWithOTP.parse(credentials) do
      UserHandler.sign_in_with_otp(client, credentials)
    end
  end

  @doc """
  Verifies an OTP code.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `params` - The parameters to use for the verification. Check `Supabase.GoTrue.Schemas.VerifyOTP` for more information.

  ## Examples
      iex> params = %Supabase.GoTrue.VerifyOTP{}
      iex> Supabase.GoTrue.verify_otp(pid | client_name, params)
      {:ok, %Supabase.GoTrue.Session{}}
  """
  @impl true
  def verify_otp(client, params) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, response} <- UserHandler.verify_otp(client, params) do
      Session.parse(response)
    end
  end

  @doc """
  Signs in a user with SSO.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `credentials` - The credentials to use for the sign in. Check `Supabase.GoTrue.Schemas.SignInWithSSO` for more information.

  ## Examples
      iex> credentials = %Supabase.GoTrue.SignInWithSSO{}
      iex> Supabase.GoTrue.sign_in_with_sso(pid | client_name, credentials)
      {:ok, %Supabase.GoTrue.User{}}
  """
  @impl true
  def sign_in_with_sso(client, credentials) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, credentials} <- SignInWithSSO.parse(credentials) do
      UserHandler.sign_in_with_sso(client, credentials)
    end
  end

  @doc """
  Signs in a user with email/phone and password.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `credentials` - The credentials to use for the sign in. Check `Supabase.GoTrue.Schemas.SignInWithPassword` for more information.

  ## Examples
      iex> credentials = %Supabase.GoTrue.SignInWithPassword{}
      iex> Supabase.GoTrue.sign_in_with_password(pid | client_name, credentials)
      {:ok, %Supabase.GoTrue.Session{}}
  """
  @impl true
  def sign_in_with_password(client, credentials) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, credentials} <- SignInWithPassword.parse(credentials),
         {:ok, response} <- UserHandler.sign_in_with_password(client, credentials) do
      Session.parse(response)
    end
  end

  @doc """
  Signs up a user with email/phone and password.

  ## Parameters
    - `client` - The `Supabase` client to use for the request.
    - `credentials` - The credentials to use for the sign up. Check `Supabase.GoTrue.Schemas.SignUpWithPassword` for more information.

  ## Examples
      iex> credentials = %Supabase.GoTrue.SignUpWithPassword{}
      iex> Supabase.GoTrue.sign_up(pid | client_name, credentials)
      {:ok, %Supabase.GoTrue.User{}}
  """
  @impl true
  def sign_up(client, credentials) when is_client(client) do
    with {:ok, client} <- Client.retrieve_client(client),
         {:ok, credentials} <- SignUpWithPassword.parse(credentials) do
      UserHandler.sign_up(client, credentials)
    end
  end

  defmacrop wrap_gotrue_functions(module) do
    quote unquote: false, bind_quoted: [module: module] do
            for {fun, arity} <- module.__info__(:functions) do
        if arity == 1 do
          quote do
            @doc """
            Check `Supabase.GoTrue.#{unquote(fun)}/#{unquote(arity)}`
            """
            def unquote(fun)() do
              apply(unquote(module), unquote(fun), [@client])
            end
          end
        else
          args = for idx <- 2..arity, do: Macro.var(:"arg#{idx}", module)

          quote do
            @doc """
            Check `Supabase.GoTrue.#{unquote(fun)}/#{unquote(arity)}`
            """
            def unquote(fun)(unquote_splicing(args)) do
              args = [unquote_splicing(args)]
              apply(unquote(module), unquote(fun), [@client | args])
            end
          end
        end
      end
    end
  end

  defmacro __using__([{:client, client} | opts]) do
    config = Macro.escape(Keyword.get(opts, :config, %{}))

    gotrue_functions = wrap_gotrue_functions(Supabase.GoTrue)
    gotrue_admin_functions = wrap_gotrue_functions(Supabase.GoTrue.Admin)

    quote location: :keep do
      @client unquote(client)

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(opts \\ []) do
        manage_clients? = Application.get_env(:supabase_potion, :manage_clients, true)

        if manage_clients? do
          Supabase.init_client(unquote(client), unquote(config))
        else

          base_url =
            Application.get_env(:supabase_potion, :supabase_base_url) ||
              raise Supabase.MissingSupabaseConfig, :url

          api_key =
            Application.get_env(:supabase_potion, :supabase_api_key) ||
              raise Supabase.MissingSupabaseConfig, :key

          config =
            unquote(config)
            |> Map.put(:conn, %{base_url: base_url, api_key: api_key})
            |> Map.put(:name, unquote(client))

          opts = [name: unquote(client), client_info: config]
          Supabase.Client.start_link(opts)
        end
        |> then(fn
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          err -> err
        end)
      end

      unquote(gotrue_functions)

      defmodule Admin do
        @client unquote(client)

        unquote(gotrue_admin_functions)
      end
    end
  end
end
