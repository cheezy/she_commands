defmodule SheCommandsWeb.Admin.UserLive.Index do
  @moduledoc """
  Admin user management. Lists every registered user with a role
  selector and an enable/disable toggle. The current admin's own row
  hides both controls; the context layer also refuses self-disable so
  the API is safe even if the UI is bypassed.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Accounts
  alias SheCommands.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Users"))
     |> assign_users()}
  end

  @impl true
  def handle_event("update_role", %{"user_id" => id, "role" => role_str}, socket) do
    role = String.to_existing_atom(role_str)
    user = Accounts.get_user!(id)

    case Accounts.update_user_role(user, role) do
      {:ok, _updated} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Role updated."))
         |> assign_users()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not update role."))}
    end
  end

  @impl true
  def handle_event("toggle_disabled", %{"id" => id}, socket) do
    actor = socket.assigns.current_scope.user
    target = Accounts.get_user!(id)

    if target.disabled do
      {:ok, _enabled} = Accounts.enable_user(target)
      {:noreply, socket |> put_flash(:info, gettext("User enabled.")) |> assign_users()}
    else
      case Accounts.disable_user(actor, target) do
        {:ok, _disabled} ->
          {:noreply, socket |> put_flash(:info, gettext("User disabled.")) |> assign_users()}

        {:error, :cannot_disable_self} ->
          {:noreply, put_flash(socket, :error, gettext("You cannot disable your own account."))}
      end
    end
  end

  defp assign_users(socket) do
    assign(socket, :users, Accounts.list_users())
  end

  @doc """
  Returns true when the row in the table is the currently logged-in
  admin. The view uses this to hide the role select and disable toggle.
  """
  def own_row?(%User{id: row_id}, %User{id: actor_id}), do: row_id == actor_id

  @doc """
  Options list for the role <select> — built from User.roles/0 so a
  new role added to the schema appears here automatically.
  """
  def role_options do
    Enum.map(User.roles(), fn role ->
      {role |> Atom.to_string() |> String.capitalize(), Atom.to_string(role)}
    end)
  end

  def display_name(%User{display_name: dn}) when is_binary(dn) and dn != "", do: dn
  def display_name(%User{name: name}) when is_binary(name) and name != "", do: name
  def display_name(%User{email: email}), do: email
end
