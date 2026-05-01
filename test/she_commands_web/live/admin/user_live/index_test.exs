defmodule SheCommandsWeb.Admin.UserLive.IndexTest do
  use SheCommandsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SheCommands.AccountsFixtures

  alias SheCommands.Accounts
  alias SheCommandsWeb.Admin.UserLive.Index

  setup :register_and_log_in_user

  describe "authorization" do
    test "redirects member users", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/admin/users")
    end
  end

  describe "as admin" do
    setup %{user: user} do
      {:ok, admin} = Accounts.update_user_role(user, :admin)
      %{admin: admin}
    end

    test "lists every user with name, email, role, and status columns", %{conn: conn} do
      member = user_fixture(%{name: "Member Person"})
      coach = coach_fixture()

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "Users"
      assert html =~ "Member Person"
      assert html =~ member.email
      assert html =~ coach.email
      assert html =~ "Active"
    end

    test "the admin's own row hides the role select and disable button", %{
      conn: conn,
      admin: admin
    } do
      {:ok, _view, html} = live(conn, ~p"/admin/users")

      # The admin's own row shows the role as text rather than a select
      assert html =~ "(you)"
      refute html =~ ~s|phx-value-id="#{admin.id}"|
    end

    test "changing role on another user via the select persists", %{conn: conn} do
      member = user_fixture()

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      view
      |> element("form[phx-change=\"update_role\"]")
      |> render_change(%{user_id: member.id, role: "coach"})

      reloaded = Accounts.get_user!(member.id)
      assert reloaded.role == :coach
    end

    test "clicking Disable on another user disables them", %{conn: conn} do
      member = user_fixture()

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      html = render_click(view, "toggle_disabled", %{"id" => to_string(member.id)})

      reloaded = Accounts.get_user!(member.id)
      assert reloaded.disabled == true
      assert html =~ "User disabled."
      assert html =~ "Disabled"
    end

    test "clicking Enable on a disabled user re-enables them", %{conn: conn, admin: admin} do
      member = user_fixture()
      {:ok, _} = Accounts.disable_user(admin, member)

      {:ok, view, _html} = live(conn, ~p"/admin/users")
      html = render_click(view, "toggle_disabled", %{"id" => to_string(member.id)})

      reloaded = Accounts.get_user!(member.id)
      assert reloaded.disabled == false
      assert html =~ "User enabled."
    end

    test "self-disable attempt via the API is refused with a flash and the row is unchanged",
         %{conn: conn, admin: admin} do
      {:ok, view, _html} = live(conn, ~p"/admin/users")

      html = render_click(view, "toggle_disabled", %{"id" => to_string(admin.id)})

      assert html =~ "You cannot disable your own account."

      reloaded = Accounts.get_user!(admin.id)
      assert reloaded.disabled == false
    end
  end

  describe "own_row?/2" do
    test "true when the row's id matches the actor's id" do
      assert Index.own_row?(%SheCommands.Accounts.User{id: 1}, %SheCommands.Accounts.User{id: 1})
    end

    test "false when ids differ" do
      refute Index.own_row?(%SheCommands.Accounts.User{id: 1}, %SheCommands.Accounts.User{id: 2})
    end
  end

  describe "role_options/0" do
    test "returns one entry per User.roles/0 atom" do
      values = Index.role_options() |> Enum.map(fn {_label, v} -> v end)
      assert values == ["member", "coach", "admin"]
    end
  end

  describe "display_name/1" do
    alias SheCommands.Accounts.User

    test "uses display_name when present" do
      assert Index.display_name(%User{display_name: "DN", name: "N", email: "e@x"}) == "DN"
    end

    test "falls back to name when display_name is blank" do
      assert Index.display_name(%User{display_name: "", name: "N", email: "e@x"}) == "N"
    end

    test "falls back to email when both name and display_name are blank" do
      assert Index.display_name(%User{display_name: nil, name: nil, email: "e@x"}) == "e@x"
    end
  end
end
