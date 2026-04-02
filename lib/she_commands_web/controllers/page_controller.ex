defmodule SheCommandsWeb.PageController do
  use SheCommandsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def brand(conn, _params) do
    render(conn, :brand)
  end
end
