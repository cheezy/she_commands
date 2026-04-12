defmodule SheCommands.ModulesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SheCommands.Modules` context.
  """

  alias SheCommands.Modules

  def module_fixture(attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    {:ok, module} =
      attrs
      |> Enum.into(%{
        module_id: "MOD-#{unique}",
        contributor: "Test Contributor #{unique}",
        title: "Test Module #{unique}",
        overview: "Overview for module #{unique}",
        core_concepts: "Core concepts #{unique}",
        power_pillar_1: :power_up,
        intensity: :moderate,
        module_type: :foundational,
        lead_time_fit: :medium
      })
      |> Modules.create_module()

    module
  end

  def module_with_categories_fixture(attrs \\ %{}, goal_categories) do
    unique = System.unique_integer([:positive])

    module_attrs =
      attrs
      |> Enum.into(%{
        module_id: "MOD-#{unique}",
        contributor: "Test Contributor #{unique}",
        title: "Test Module #{unique}",
        power_pillar_1: :power_up,
        intensity: :moderate,
        module_type: :foundational,
        lead_time_fit: :medium
      })

    {:ok, module} = Modules.create_module_with_categories(module_attrs, goal_categories)

    module
  end

  def protocol_fixture(module, attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    {:ok, protocol} =
      attrs
      |> Enum.into(%{
        module_id: module.id,
        position: rem(unique, 4) + 1,
        purpose: "Purpose #{unique}",
        steps: "Steps #{unique}",
        prescription: "Prescription #{unique}",
        expected_outcome: "Expected outcome #{unique}"
      })
      |> Modules.create_protocol()

    protocol
  end
end
