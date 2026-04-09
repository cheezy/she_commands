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

  def connect(conn, _params) do
    render(conn, :connect)
  end

  def the_journal(conn, _params) do
    render(conn, :the_journal)
  end
end
