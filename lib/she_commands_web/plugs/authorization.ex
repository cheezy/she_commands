defmodule SheCommandsWeb.Plugs.Authorization do
  @moduledoc """
  Plug for role-based route protection.

  Checks that the authenticated user has the required role(s)
  and redirects with an error flash if not authorized.

  ## Usage

      plug SheCommandsWeb.Plugs.Authorization, :admin
      plug SheCommandsWeb.Plugs.Authorization, [:admin, :coach]
  """

  use SheCommandsWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  def init(roles) when is_list(roles), do: roles
  def init(role) when is_atom(role), do: [role]

  def call(conn, roles) do
    user = conn.assigns[:current_scope] && conn.assigns.current_scope.user

    if user && user.role in roles do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this page.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
