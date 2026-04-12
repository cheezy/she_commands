defmodule SheCommandsWeb.PlanController do
  use SheCommandsWeb, :controller

  alias SheCommands.Plans

  def print(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user
    plan = Plans.get_plan!(id)

    if plan.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You are not authorized to view this plan."))
      |> redirect(to: ~p"/")
    else
      conn
      |> put_layout(false)
      |> put_root_layout(false)
      |> render(:print, plan: plan)
    end
  end
end
