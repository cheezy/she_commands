ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SheCommands.Repo, :manual)

# Drop the noisy "Postgrex.Protocol disconnected: client <pid> exited" log
# that fires when an async test process exits while a Phoenix.PubSub-subscribed
# LiveView still holds a sandbox connection. These are benign — the test passed
# and Ecto.Adapters.SQL.Sandbox releases the connection cleanly — only the log
# line is noise. Real disconnect errors (no "client" trailer) still pass through.
:logger.add_primary_filter(
  :drop_postgrex_client_exited,
  {fn event, _state ->
     msg =
       case event do
         %{msg: {:string, str}} ->
           IO.iodata_to_binary(str)

         %{msg: {:report, %{format: format, args: args}}} ->
           IO.iodata_to_binary(:io_lib.format(format, args))

         %{msg: {format, args}} when is_list(format) or is_binary(format) ->
           IO.iodata_to_binary(:io_lib.format(format, args))

         _ ->
           ""
       end

     if String.contains?(msg, "Postgrex.Protocol") and
          String.contains?(msg, "client #PID") and
          String.contains?(msg, "exited") do
       :stop
     else
       :ignore
     end
   end, []}
)
