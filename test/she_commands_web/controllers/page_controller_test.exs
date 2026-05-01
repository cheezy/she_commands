defmodule SheCommandsWeb.PageControllerTest do
  use SheCommandsWeb.ConnCase

  import SheCommands.AccountsFixtures

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "She Commands"
  end

  describe "Admin nav link" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "is rendered for admin users", %{conn: conn, user: user} do
      {:ok, _admin} = SheCommands.Accounts.update_user_role(user, :admin)

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      assert html =~ ~s|href="/admin"|
      assert html =~ ">\n                  Admin\n                </a>"
    end

    test "is hidden for member users", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      refute html =~ ~s|href="/admin"|
    end

    test "is hidden for coach users", %{conn: conn, user: user} do
      {:ok, _coach} = SheCommands.Accounts.update_user_role(user, :coach)

      conn = get(conn, ~p"/")
      html = html_response(conn, 200)
      refute html =~ ~s|href="/admin"|
    end
  end
end
