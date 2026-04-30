defmodule SheCommands.ApplicationTest do
  use ExUnit.Case, async: true

  describe "supervision tree" do
    test "Oban is started under the application supervisor" do
      children =
        SheCommands.Supervisor
        |> Supervisor.which_children()
        |> Enum.map(fn {id, _pid, _type, _mods} -> id end)

      assert Oban in children
    end

    test "Oban is configured with the :feedback queue" do
      config = Oban.config()
      # In :inline test mode the queues map is empty, but the queue
      # should still be present in the configured-but-not-running state.
      configured = Application.fetch_env!(:she_commands, Oban)
      assert config
      assert Keyword.fetch!(configured, :queues) == [feedback: 5]
    end
  end
end
