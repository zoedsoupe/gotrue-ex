defmodule Supabase.GoTrue.AdminHandler do
  @moduledoc false

  alias Supabase.Client
  alias Supabase.Fetcher
  alias Supabase.GoTrue.Schemas.InviteUserParams

  @invite "/invite"
  @generate_link "/admin/generate_link"
  @users "/admin/users"

  defp single_user_endpoint(id) do
    @users <> "/#{id}"
  end

  defp sign_out(scope) do
    "/logout?scope=#{scope}"
  end

  def sign_out(%Client{} = client, access_token, scope) do
    endpoint = Client.retrieve_auth_url(client, sign_out(scope))
    headers = Fetcher.apply_client_headers(client, access_token)
    Fetcher.post(endpoint, nil, headers, resolve_json: true)
  end

  def invite_user(%Client{} = client, email, %InviteUserParams{} = opts) do
    headers = Fetcher.apply_client_headers(client, client.conn.api_key, %{"redirect_to" => opts.redirect_to})
    body = %{email: email, data: opts.data}

    client
    |> Client.retrieve_auth_url(@invite)
    |> Fetcher.post(body, headers, resolve_json: true)
  end

  def generate_link(%Client{} = client, %{type: _, redirect_to: redirect_to} = params) do
    headers = Fetcher.apply_client_headers(client, client.conn.api_key, %{"redirect_to" => redirect_to})

    client
    |> Client.retrieve_auth_url(@generate_link)
    |> Fetcher.post(params, headers, resolve_json: true)
  end

  def create_user(%Client{} = client, params) do
    headers = Fetcher.apply_client_headers(client, client.conn.api_key)

    client
    |> Client.retrieve_auth_url(@users)
    |> Fetcher.post(params, headers, resolve_json: true)
  end

  def delete_user(%Client{} = client, id, params) do
    headers = Fetcher.apply_client_headers(client, client.conn.api_key)
    body = %{should_soft_delete: params[:should_soft_delete] || false}
    uri = single_user_endpoint(id)

    client
    |> Client.retrieve_auth_url(uri)
    |> Fetcher.delete(body, headers, resolve_json: true)
  end

  def get_user(%Client{} = client, id) do
    headers = Fetcher.apply_client_headers(client, client.conn.api_key)
    uri = single_user_endpoint(id)

    client
    |> Client.retrieve_auth_url(uri)
    |> Fetcher.get(nil, headers, resolve_json: true)
  end

  def list_users(%Client{} = client, params) do
    query = URI.encode_query %{
      page: to_string(Map.get(params, :page, 1)),
      per_page: to_string(Map.get(params, :per_page, nil))
    }

    headers = Fetcher.apply_client_headers(client, client.conn.api_key)

    client
    |> Client.retrieve_auth_url(@users)
    |> URI.new!()
    |> URI.append_query(query)
    |> Fetcher.get(nil, headers, resolve_json: false)
    |> case do
      {:ok, resp} when resp.status == 200 -> {:ok, Map.update!(resp, :body, &Jason.decode!/1)}
      {:ok, resp} -> {:ok, Fetcher.format_response(resp)}
      {:error, _} = err -> err
    end
  end

  def update_user(%Client{} = client, id, params) do
    headers = Fetcher.apply_client_headers(client, client.conn.api_key)
    uri = single_user_endpoint(id)

    client
    |> Client.retrieve_auth_url(uri)
    |> Fetcher.put(params, headers, resolve_json: true)
  end
end
