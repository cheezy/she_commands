defmodule SheCommandsWeb.PageController do
  use SheCommandsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
