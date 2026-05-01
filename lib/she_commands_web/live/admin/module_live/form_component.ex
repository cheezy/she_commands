defmodule SheCommandsWeb.Admin.ModuleLive.FormComponent do
  @moduledoc """
  Modal form for creating or updating a `SheCommands.Modules.Module`.

  Branches on `assigns.module.id`: nil routes to
  `Modules.create_module_with_categories/2`, otherwise to
  `Modules.update_module_with_categories/3`. The goal_categories
  many_to_many is handled outside `Module.changeset/2` because that
  changeset's cast list does not include the association — the put_assoc
  happens in the context helpers.
  """

  use SheCommandsWeb, :live_component

  alias SheCommands.Intake
  alias SheCommands.Modules

  @impl true
  def update(%{record: record} = assigns, socket) do
    available_categories = Map.get(assigns, :goal_categories) || Intake.list_goal_categories()
    record_categories = if Ecto.assoc_loaded?(record.goal_categories), do: record.goal_categories, else: []
    selected_ids = Enum.map(record_categories, & &1.id)

    changeset = Modules.change_module(record, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:available_categories, available_categories)
     |> assign(:selected_category_ids, selected_ids)
     |> assign_new(:return_to, fn -> "/admin/modules" end)}
  end

  @impl true
  def handle_event("validate", %{"module" => params}, socket) do
    changeset =
      socket.assigns.record
      |> Modules.change_module(params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:selected_category_ids, parse_category_ids(params))}
  end

  @impl true
  def handle_event("save", %{"module" => params}, socket) do
    selected_ids = parse_category_ids(params)
    selected_categories = Enum.filter(socket.assigns.available_categories, &(&1.id in selected_ids))

    save(socket, socket.assigns.record, params, selected_categories)
  end

  defp save(socket, %SheCommands.Modules.Module{id: nil}, params, categories) do
    case Modules.create_module_with_categories(params, categories) do
      {:ok, module} ->
        notify_parent({:saved, module})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save(socket, %SheCommands.Modules.Module{} = existing, params, categories) do
    case Modules.update_module_with_categories(existing, params, categories) do
      {:ok, module} ->
        notify_parent({:saved, module})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp notify_parent(message), do: send(self(), message)

  defp parse_category_ids(%{"goal_category_ids" => ids}) when is_list(ids) do
    ids
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_int/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_category_ids(_), do: []

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp to_int(_), do: nil

  @doc """
  True when the form is being shown for an unsaved (new) module.
  """
  def new?(changeset), do: is_nil(Ecto.Changeset.get_field(changeset, :id))

  defp pillar_options do
    Enum.map(SheCommands.Modules.Module.power_pillars(), fn p ->
      {p |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize(), Atom.to_string(p)}
    end)
  end

  defp module_type_options do
    Enum.map(SheCommands.Modules.Module.module_types(), &simple_option/1)
  end

  defp intensity_options do
    Enum.map(SheCommands.Modules.Module.intensities(), &simple_option/1)
  end

  defp lead_time_fit_options do
    Enum.map(SheCommands.Modules.Module.lead_time_fits(), &simple_option/1)
  end

  defp simple_option(atom) do
    {atom |> Atom.to_string() |> String.capitalize(), Atom.to_string(atom)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center bg-base-200/90 p-4"
    >
      <div class="w-full max-w-3xl bg-base-100 border border-base-300 max-h-[90vh] overflow-y-auto">
        <div class="px-6 py-4 border-b border-base-300 flex items-center justify-between sticky top-0 bg-base-100 z-10">
          <h2 class="text-2xl font-serif italic text-base-content">
            <%= if new?(@changeset) do %>
              {gettext("New module")}
            <% else %>
              {gettext("Edit module")}
            <% end %>
          </h2>
          <.link
            patch={@return_to}
            class="text-base-content/40 hover:text-base-content transition cursor-pointer"
            aria-label={gettext("Close")}
          >
            <.icon name="hero-x-mark" class="size-5" />
          </.link>
        </div>

        <.form
          :let={f}
          for={@changeset}
          as={:module}
          id={"#{@id}-form"}
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
          class="p-6 space-y-5"
        >
          <section class="space-y-3">
            <h3 class="font-label text-xs uppercase tracking-[0.15em] text-base-content/60">
              {gettext("Identity")}
            </h3>
            <.input field={f[:module_id]} type="text" label={gettext("Module ID")} required />
            <.input field={f[:title]} type="text" label={gettext("Title")} required />
            <.input field={f[:contributor]} type="text" label={gettext("Contributor")} required />
            <.input field={f[:overview]} type="textarea" label={gettext("Overview")} rows="2" />
            <.input field={f[:core_concepts]} type="textarea" label={gettext("Core concepts")} rows="2" />
          </section>

          <section class="space-y-3">
            <h3 class="font-label text-xs uppercase tracking-[0.15em] text-base-content/60">
              {gettext("Categorization")}
            </h3>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <.input
                field={f[:power_pillar_1]}
                type="select"
                label={gettext("Primary pillar")}
                options={pillar_options()}
                prompt={gettext("Select a pillar...")}
              />
              <.input
                field={f[:power_pillar_2]}
                type="select"
                label={gettext("Secondary pillar")}
                options={pillar_options()}
                prompt={gettext("(optional)")}
              />
              <.input
                field={f[:module_type]}
                type="select"
                label={gettext("Module type")}
                options={module_type_options()}
              />
              <.input
                field={f[:intensity]}
                type="select"
                label={gettext("Intensity")}
                options={intensity_options()}
              />
              <.input
                field={f[:lead_time_fit]}
                type="select"
                label={gettext("Lead time fit")}
                options={lead_time_fit_options()}
              />
              <.input
                field={f[:experience_level]}
                type="text"
                label={gettext("Experience level")}
              />
            </div>

            <fieldset class="space-y-2">
              <label
                for={"#{@id}-categories"}
                class="font-label text-xs uppercase tracking-[0.15em] text-base-content/70 block"
              >
                {gettext("Goal categories")}
              </label>
              <select
                id={"#{@id}-categories"}
                name="module[goal_category_ids][]"
                multiple
                size="6"
                class="w-full bg-base-100 border border-base-300 px-3 py-2 text-sm text-base-content focus:outline-none focus:border-base-content"
              >
                <%= for cat <- @available_categories do %>
                  <option value={cat.id} selected={cat.id in @selected_category_ids}>
                    {cat.name}
                  </option>
                <% end %>
              </select>
              <p class="text-xs text-base-content/50">
                {gettext("Hold Cmd/Ctrl to select multiple.")}
              </p>
            </fieldset>
          </section>

          <section class="space-y-3">
            <h3 class="font-label text-xs uppercase tracking-[0.15em] text-base-content/60">
              {gettext("Outcomes & sequencing")}
            </h3>
            <.input field={f[:outcomes]} type="textarea" label={gettext("Outcomes")} rows="2" />
            <.input
              field={f[:protocol_sequencing]}
              type="textarea"
              label={gettext("Protocol sequencing")}
              rows="2"
            />
            <.input field={f[:modifications]} type="textarea" label={gettext("Modifications")} rows="2" />
            <.input field={f[:time_to_result]} type="text" label={gettext("Time to result")} />
          </section>

          <section class="space-y-3">
            <h3 class="font-label text-xs uppercase tracking-[0.15em] text-base-content/60">
              {gettext("Time & frequency")}
            </h3>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <.input field={f[:daily_time]} type="number" label={gettext("Daily time (min)")} />
              <.input field={f[:weekly_freq]} type="number" label={gettext("Weekly frequency")} />
              <.input field={f[:daily_freq]} type="number" label={gettext("Daily frequency")} />
            </div>
          </section>

          <section class="space-y-3">
            <h3 class="font-label text-xs uppercase tracking-[0.15em] text-base-content/60">
              {gettext("Coach tip")}
            </h3>
            <.input field={f[:coach_tip]} type="textarea" label={gettext("Coach tip")} rows="2" />
            <.input
              field={f[:coach_tip_attribution]}
              type="text"
              label={gettext("Coach tip attribution")}
            />
          </section>

          <section class="space-y-3">
            <h3 class="font-label text-xs uppercase tracking-[0.15em] text-base-content/60">
              {gettext("Sources & flags")}
            </h3>
            <.input field={f[:sources]} type="textarea" label={gettext("Sources")} rows="2" />
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <.input field={f[:video_available]} type="checkbox" label={gettext("Video available")} />
              <.input field={f[:reward_eligible]} type="checkbox" label={gettext("Reward eligible")} />
            </div>
          </section>

          <div class="flex justify-end gap-3 pt-4 border-t border-base-300">
            <.link
              patch={@return_to}
              class="py-3 px-6 text-xs font-label uppercase tracking-[0.2em] text-base-content/60 hover:text-base-content transition"
            >
              {gettext("Cancel")}
            </.link>
            <button
              type="submit"
              class="py-3 px-8 bg-base-content text-base-100 text-xs font-label uppercase tracking-[0.2em] hover:bg-base-content/90 transition cursor-pointer"
            >
              {gettext("Save")}
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
