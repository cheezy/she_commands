defmodule SheCommandsWeb.Plugs.AuthorizationTest do
  use SheCommandsWeb.ConnCase, async: true

  import SheCommands.AccountsFixtures

  alias SheCommandsWeb.Plugs.Authorization

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, SheCommandsWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})
      |> fetch_flash()

    {:ok, conn: conn}
  end

  describe "call/2 with single role" do
    test "allows access when user has the required role", %{conn: conn} do
      user = admin_fixture()
      scope = SheCommands.Accounts.Scope.for_user(user)

      conn =
        conn
        |> assign(:current_scope, scope)
        |> Authorization.call(Authorization.init(:admin))

      refute conn.halted
    end

    test "denies access when user does not have the required role", %{conn: conn} do
      user = user_fixture()
      scope = SheCommands.Accounts.Scope.for_user(user)

      conn =
        conn
        |> assign(:current_scope, scope)
        |> Authorization.call(Authorization.init(:admin))

      assert conn.halted
      assert redirected_to(conn) == "/"
    end
  end

  describe "call/2 with multiple roles" do
    test "allows access when user has one of the required roles", %{conn: conn} do
      user = coach_fixture()
      scope = SheCommands.Accounts.Scope.for_user(user)

      conn =
        conn
        |> assign(:current_scope, scope)
        |> Authorization.call(Authorization.init([:coach, :admin]))

      refute conn.halted
    end

    test "denies access when user has none of the required roles", %{conn: conn} do
      user = user_fixture()
      scope = SheCommands.Accounts.Scope.for_user(user)

      conn =
        conn
        |> assign(:current_scope, scope)
        |> Authorization.call(Authorization.init([:coach, :admin]))

      assert conn.halted
      assert redirected_to(conn) == "/"
    end
  end

  describe "call/2 with no user" do
    test "denies access when no user is authenticated", %{conn: conn} do
      conn =
        conn
        |> assign(:current_scope, nil)
        |> Authorization.call(Authorization.init(:admin))

      assert conn.halted
      assert redirected_to(conn) == "/"
    end
  end
end
