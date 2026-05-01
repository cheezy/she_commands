defmodule SheCommandsWeb.Admin.DashboardLive.Index do
  @moduledoc """
  Admin landing page. Renders three iconified shortcuts to the
  Modules library, Goal Categories visibility manager, and Success
  Metrics dashboard.

  Gated by the `:ensure_admin` on_mount hook on the admin live_session.
  """

  use SheCommandsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, gettext("Admin"))}
  end
end
