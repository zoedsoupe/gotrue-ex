defmodule Supabase.GoTrue.UserHandler do
  @moduledoc false

  alias Supabase.Client
  alias Supabase.Fetcher
  alias Supabase.GoTrue
  alias Supabase.GoTrue.LiveView
  alias Supabase.GoTrue.PKCE
  alias Supabase.GoTrue.Schemas.SignInRequest
  alias Supabase.GoTrue.Schemas.SignInWithIdToken
  alias Supabase.GoTrue.Schemas.SignInWithOauth
  alias Supabase.GoTrue.Schemas.SignInWithOTP
  alias Supabase.GoTrue.Schemas.SignInWithPassword
  alias Supabase.GoTrue.Schemas.SignInWithSSO
  alias Supabase.GoTrue.Schemas.SignUpRequest
  alias Supabase.GoTrue.Schemas.SignUpWithPassword
  alias Supabase.GoTrue.Schemas.VerifyOTP
  alias Supabase.GoTrue.User

  @single_user_uri "/user"
  @sign_in_uri "/token"
  @sign_up_uri "/signup"
  @oauth_uri "/authorize"
  @sso_uri "/sso"
  @otp_uri "/otp"
  @verify_otp_uri "/verify"
  @reset_pass_uri "/recover"
  @resend_signup_uri "/resend"

  def get_user(%Client{} = client, access_token) do
    headers = Fetcher.apply_client_headers(client, access_token)

    client
    |> Client.retrieve_auth_url(@single_user_uri)
    |> Fetcher.get(nil, headers, resolve_json: true)
  end

  def verify_otp(%Client{} = client, %{} = params) do
    with {:ok, request} <- VerifyOTP.to_request(params) do
      headers = Fetcher.apply_client_headers(client)
      endpoint = Client.retrieve_auth_url(client, @verify_otp_uri)
      endpoint = append_query(endpoint, %{redirect_to: get_in(request, [:options, :redirect_to])})
      Fetcher.post(endpoint, request, headers, resolve_json: true)
    end
  end

  def sign_in_with_otp(%Client{} = client, %SignInWithOTP{} = signin)
      when client.auth.flow_type == :pkce do
    {challenge, method} = generate_pkce()

    with {:ok, request} <- SignInRequest.create(signin, challenge, method),
         headers = Fetcher.apply_client_headers(client),
         endpoint = Client.retrieve_auth_url(client, @otp_uri),
         endpoint = append_query(endpoint, %{redirect_to: request.redirect_to}),
         {:ok, response} <- Fetcher.post(endpoint, request, headers, resolve_json: true) do
      if is_nil(signin.email), do: {:ok, response["data"]["message_id"]}, else: :ok
    end
  end

  def sign_in_with_otp(%Client{} = client, %SignInWithOTP{} = signin) do
    with {:ok, request} <- SignInRequest.create(signin),
         headers = Fetcher.apply_client_headers(client),
         endpoint = Client.retrieve_auth_url(client, @otp_uri),
         endpoint = append_query(endpoint, %{redirect_to: request.redirect_to}),
         {:ok, response} <- Fetcher.post(endpoint, request, headers, resolve_json: true) do
      if is_nil(signin.email), do: {:ok, response["data"]["message_id"]}, else: :ok
    end
  end

  def sign_in_with_sso(%Client{} = client, %SignInWithSSO{} = signin)
      when client.auth.flow_type == :pkce do
    {challenge, method} = generate_pkce()

    with {:ok, request} <- SignInRequest.create(signin, challenge, method),
         headers = Fetcher.apply_client_headers(client),
         endpoint = Client.retrieve_auth_url(client, @sso_uri),
         endpoint = append_query(endpoint, %{redirect_to: request.redirect_to}),
         {:ok, response} <- Fetcher.post(endpoint, request, headers, resolve_json: true) do
      {:ok, response["data"]["url"]}
    end
  end

  def sign_in_with_sso(%Client{} = client, %SignInWithSSO{} = signin) do
    with {:ok, request} <- SignInRequest.create(signin),
         headers = Fetcher.apply_client_headers(client),
         endpoint = Client.retrieve_auth_url(client, @sso_uri),
         endpoint = append_query(endpoint, %{redirect_to: request.redirect_to}),
         {:ok, response} <- Fetcher.post(endpoint, request, headers, resolve_json: true) do
      {:ok, response["data"]["url"]}
    end
  end

  @grant_types ~w[password id_token]

  def sign_in_with_password(%Client{} = client, %SignInWithPassword{} = signin) do
    with {:ok, request} <- SignInRequest.create(signin) do
      sign_in_request(client, request, "password")
    end
  end

  def sign_in_with_id_token(%Client{} = client, %SignInWithIdToken{} = signin) do
    with {:ok, request} <- SignInRequest.create(signin) do
      sign_in_request(client, request, "id_token")
    end
  end

  defp sign_in_request(%Client{} = client, %SignInRequest{} = request, grant_type)
       when grant_type in @grant_types do
    headers = Fetcher.apply_client_headers(client)

    client
    |> Client.retrieve_auth_url(@sign_in_uri)
    |> append_query(%{grant_type: grant_type, redirect_to: request.redirect_to})
    |> Fetcher.post(request, headers, resolve_json: true)
  end

  def sign_up(%Client{} = client, %SignUpWithPassword{} = signup)
      when client.auth.flow_type == :pkce do
    {challenge, method} = generate_pkce()

    with {:ok, request} <- SignUpRequest.create(signup, challenge, method),
         headers = Fetcher.apply_client_headers(client),
         endpoint = Client.retrieve_auth_url(client, @sign_up_uri),
         {:ok, response} <- Fetcher.post(endpoint, request, headers, resolve_json: true),
         {:ok, user} <- User.parse(response) do
      {:ok, user, challenge}
    end
  end

  def sign_up(%Client{} = client, %SignUpWithPassword{} = signup) do
    with {:ok, request} <- SignUpRequest.create(signup),
         headers = Fetcher.apply_client_headers(client),
         endpoint = Client.retrieve_auth_url(client, @sign_up_uri),
         {:ok, response} <- Fetcher.post(endpoint, request, headers, resolve_json: true) do
      User.parse(response)
    end
  end

  def recover_password(%Client{} = client, email, %{} = opts)
      when client.auth.flow_type == :pkce do
    {challenge, method} = generate_pkce()

    body = %{
      email: email,
      code_challenge: challenge,
      code_challenge_method: method,
      go_true_meta_security: %{captcha_token: opts[:captcha_token]}
    }

    headers = Fetcher.apply_client_headers(client)
    endpoint = Client.retrieve_auth_url(client, @reset_pass_uri)
    endpoint = append_query(endpoint, %{redirect_to: opts[:redirect_to]})

    with {:ok, _} <- Fetcher.post(endpoint, body, headers) do
      :ok
    end
  end

  def recover_password(%Client{} = client, email, %{} = opts) do
    body = %{
      email: email,
      go_true_meta_security: %{captcha_token: opts[:captcha_token]}
    }

    headers = Fetcher.apply_client_headers(client)
    endpoint = Client.retrieve_auth_url(client, @reset_pass_uri)
    endpoint = append_query(endpoint, %{redirect_to: opts[:redirect_to]})

    with {:ok, _} <- Fetcher.post(endpoint, body, headers) do
      :ok
    end
  end

  def resend_signup(%Client{} = client, email, %{} = opts) do
    body = %{
      email: email,
      type: opts.type,
      go_true_meta_security: %{captcha_token: opts[:captcha_token]}
    }

    headers = Fetcher.apply_client_headers(client)
    endpoint = Client.retrieve_auth_url(client, @resend_signup_uri)
    endpoint = append_query(endpoint, %{redirect_to: opts[:redirect_to]})

    with {:ok, _} <- Fetcher.post(endpoint, body, headers) do
      :ok
    end
  end

  def update_user(%Client{} = client, conn, %{} = params)
      when client.auth.flow_type == :pkce do
    {challenge, method} = generate_pkce()

    access_token =
      case conn do
        %Plug.Conn{} -> Plug.Conn.get_session(conn, :user_token)
        %Phoenix.LiveView.Socket{} -> conn.assigns.user_token
      end

    body = Map.merge(params, %{code_challenge: challenge, code_challenge_method: method})
    headers = Fetcher.apply_client_headers(client, access_token)
    endpoint = Client.retrieve_auth_url(client, @single_user_uri)
    endpoint = append_query(endpoint, %{redirect_to: params[:email_redirect_to]})

    session = %{"user_token" => access_token}

    with {:ok, _} <- Fetcher.put(endpoint, body, headers) do
      case conn do
        %Plug.Conn{} -> {:ok, GoTrue.Plug.fetch_current_user(conn, nil)}
        %Phoenix.LiveView.Socket{} -> {:ok, LiveView.mount_current_user(session, conn)}
      end
    end
  end

  def update_user(%Client{} = client, conn, %{} = params) do
    access_token =
      case conn do
        %Plug.Conn{} -> Plug.Conn.get_session(conn, :user_token)
        %Phoenix.LiveView.Socket{} -> conn.assigns.user_token
      end

    headers = Fetcher.apply_client_headers(client, access_token)
    endpoint = Client.retrieve_auth_url(client, @single_user_uri)
    endpoint = append_query(endpoint, %{redirect_to: params[:email_redirect_to]})

    session = %{"user_token" => access_token}

    with {:ok, _} <- Fetcher.put(endpoint, params, headers) do
      case conn do
        %Plug.Conn{} -> {:ok, GoTrue.Plug.fetch_current_user(conn, nil)}
        %Phoenix.LiveView.Socket{} -> {:ok, LiveView.mount_current_user(session, conn)}
      end
    end
  end

  def get_url_for_provider(%Client{} = client, %SignInWithOauth{} = oauth)
      when client.auth.flow_type == :pkce do
    {challenge, method} = generate_pkce()
    pkce_query = %{code_challenge: challenge, code_challenge_method: method}
    oauth_query = SignInWithOauth.options_to_query(oauth)

    client
    |> Client.retrieve_auth_url(@oauth_uri)
    |> append_query(Map.merge(pkce_query, oauth_query))
  end

  def get_url_for_provider(%Client{} = client, %SignInWithOauth{} = oauth) do
    oauth_query = SignInWithOauth.options_to_query(oauth)

    client
    |> Client.retrieve_auth_url(@oauth_uri)
    |> append_query(oauth_query)
  end

  defp append_query(%URI{} = uri, query) do
    query = Map.filter(query, &(not is_nil(elem(&1, 1))))
    encoded = URI.encode_query(query)
    URI.append_query(uri, encoded)
  end

  defp append_query(uri, query) when is_binary(uri) do
    append_query(URI.new!(uri), query)
  end

  defp generate_pkce do
    verifier = PKCE.generate_verifier()
    challenge = PKCE.generate_challenge(verifier)
    method = if verifier == challenge, do: "plain", else: "s256"
    {challenge, method}
  end
end
