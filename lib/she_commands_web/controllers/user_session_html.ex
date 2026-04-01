defmodule SheCommandsWeb.UserSessionHTML do
  use SheCommandsWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:she_commands, SheCommands.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
