defmodule SheCommandsWeb.Admin.MetricsLive.Index do
  @moduledoc """
  Admin success-metrics dashboard. Renders five cards backed by simple
  aggregate queries from the Intake, Plans, Feedback, and Escalations
  contexts. Targets are MVP guidance, not blocking thresholds.
  """

  use SheCommandsWeb, :live_view

  alias SheCommands.Escalations
  alias SheCommands.Feedback
  alias SheCommands.Intake
  alias SheCommands.Plans

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Success metrics"))
     |> assign(:metrics, load_metrics())}
  end

  defp load_metrics do
    [
      %{
        key: :onboarding,
        label: gettext("Onboarding completion"),
        value: Intake.onboarding_completion_rate(),
        target: 0.50,
        direction: :higher
      },
      %{
        key: :module_views,
        label: gettext("Module engagement"),
        value: Plans.module_engagement_rate(),
        target: 0.40,
        direction: :higher
      },
      %{
        key: :plan_completion,
        label: gettext("Plan completion"),
        value: Plans.completion_rate(),
        target: 0.20,
        direction: :higher
      },
      %{
        key: :survey_completion,
        label: gettext("Post-plan survey completion"),
        value: Feedback.survey_completion_rate(),
        target: 0.20,
        direction: :higher
      },
      %{
        key: :escalation_volume,
        label: gettext("Escalation volume"),
        value: Escalations.escalation_volume_rate(),
        target: 0.25,
        direction: :lower
      }
    ]
  end

  @doc """
  Returns `:on_target` or `:off_target` for a metric. For `:higher`
  metrics the value must meet or exceed the target; for `:lower`
  metrics the value must stay at or below the target.
  """
  def metric_status(%{value: value, target: target, direction: :higher}),
    do: if(value >= target, do: :on_target, else: :off_target)

  def metric_status(%{value: value, target: target, direction: :lower}),
    do: if(value <= target, do: :on_target, else: :off_target)

  def percent(value) when is_float(value), do: "#{round(value * 100)}%"
  def percent(_), do: "0%"
end
