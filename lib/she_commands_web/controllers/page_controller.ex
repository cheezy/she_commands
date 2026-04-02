defmodule SheCommandsWeb.PageController do
  use SheCommandsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def brand(conn, _params) do
    render(conn, :brand)
  end

  def goal_execution(conn, _params) do
    render(conn, :goal_execution)
  end

  def experiences(conn, _params) do
    render(conn, :experiences)
  end
end
