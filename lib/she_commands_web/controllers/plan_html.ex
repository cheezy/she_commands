defmodule SheCommandsWeb.PlanHTML do
  @moduledoc """
  HTML views for plan rendering (print/PDF view).
  """
  use SheCommandsWeb, :html

  embed_templates "plan_html/*"
end
