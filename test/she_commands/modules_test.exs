defmodule SheCommands.ModulesTest do
  use SheCommands.DataCase, async: true

  import SheCommands.IntakeFixtures
  import SheCommands.ModulesFixtures

  alias SheCommands.Modules

  describe "list_modules/0" do
    test "returns all modules ordered by title" do
      m1 = module_fixture(%{title: "Zebra Module"})
      m2 = module_fixture(%{title: "Alpha Module"})

      modules = Modules.list_modules()
      assert [first, second] = modules
      assert first.id == m2.id
      assert second.id == m1.id
    end

    test "preloads protocols and goal_categories" do
      module = module_fixture()
      protocol_fixture(module, %{position: 1})

      [loaded] = Modules.list_modules()
      assert Ecto.assoc_loaded?(loaded.protocols)
      assert Ecto.assoc_loaded?(loaded.goal_categories)
      assert length(loaded.protocols) == 1
    end

    test "returns empty list when no modules exist" do
      assert Modules.list_modules() == []
    end
  end

  describe "get_module!/1" do
    test "returns the module with given id" do
      module = module_fixture()
      loaded = Modules.get_module!(module.id)
      assert loaded.id == module.id
      assert loaded.title == module.title
    end

    test "preloads protocols and goal_categories" do
      module = module_fixture()
      protocol_fixture(module, %{position: 1})

      loaded = Modules.get_module!(module.id)
      assert Ecto.assoc_loaded?(loaded.protocols)
      assert Ecto.assoc_loaded?(loaded.goal_categories)
    end

    test "raises when module does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Modules.get_module!(0)
      end
    end
  end

  describe "get_module_by_module_id/1" do
    test "returns the module with matching module_id" do
      module = module_fixture(%{module_id: "MOD-UNIQUE-1"})
      loaded = Modules.get_module_by_module_id("MOD-UNIQUE-1")
      assert loaded.id == module.id
    end

    test "returns nil when not found" do
      assert Modules.get_module_by_module_id("nonexistent") == nil
    end
  end

  describe "create_module/1" do
    test "creates a module with valid attrs" do
      attrs = %{
        module_id: "MOD-NEW",
        contributor: "Paula V",
        title: "New Module",
        power_pillar_1: :power_up
      }

      assert {:ok, module} = Modules.create_module(attrs)
      assert module.module_id == "MOD-NEW"
      assert module.contributor == "Paula V"
      assert module.title == "New Module"
      assert module.power_pillar_1 == :power_up
    end

    test "returns error with invalid attrs" do
      assert {:error, changeset} = Modules.create_module(%{})
      refute changeset.valid?
    end

    test "enforces unique module_id" do
      module_fixture(%{module_id: "MOD-DUP"})

      assert {:error, changeset} =
               Modules.create_module(%{
                 module_id: "MOD-DUP",
                 contributor: "Test",
                 title: "Duplicate",
                 power_pillar_1: :power_up
               })

      assert "has already been taken" in errors_on(changeset).module_id
    end
  end

  describe "create_module_with_categories/2" do
    test "creates a module with goal category associations" do
      cat1 = goal_category_fixture(%{name: "Cat A", slug: "cat-a-#{System.unique_integer()}"})
      cat2 = goal_category_fixture(%{name: "Cat B", slug: "cat-b-#{System.unique_integer()}"})

      attrs = %{
        module_id: "MOD-CAT-1",
        contributor: "Andrea F",
        title: "Multi-Category Module",
        power_pillar_1: :empower
      }

      assert {:ok, module} = Modules.create_module_with_categories(attrs, [cat1, cat2])
      loaded = Modules.get_module!(module.id)
      assert length(loaded.goal_categories) == 2
    end

    test "module can belong to 1 goal category" do
      cat = goal_category_fixture()

      attrs = %{
        module_id: "MOD-CAT-SINGLE",
        contributor: "Jenna M",
        title: "Single Category Module",
        power_pillar_1: :power_through
      }

      assert {:ok, module} = Modules.create_module_with_categories(attrs, [cat])
      loaded = Modules.get_module!(module.id)
      assert length(loaded.goal_categories) == 1
    end
  end

  describe "update_module/2" do
    test "updates a module with valid attrs" do
      module = module_fixture()
      assert {:ok, updated} = Modules.update_module(module, %{title: "Updated Title"})
      assert updated.title == "Updated Title"
    end
  end

  describe "delete_module/1" do
    test "deletes a module and its protocols" do
      module = module_fixture()
      protocol_fixture(module, %{position: 1})

      assert {:ok, _} = Modules.delete_module(module)
      assert Modules.list_modules() == []
      assert Modules.list_protocols_for_module(module.id) == []
    end
  end

  describe "change_module/2" do
    test "returns a changeset" do
      module = module_fixture()
      assert %Ecto.Changeset{} = Modules.change_module(module)
    end
  end

  describe "list_modules_by_goal_category/1" do
    test "returns modules for a specific goal category" do
      cat1 = goal_category_fixture(%{name: "Cat 1", slug: "gc-#{System.unique_integer()}"})
      cat2 = goal_category_fixture(%{name: "Cat 2", slug: "gc-#{System.unique_integer()}"})

      m1 = module_with_categories_fixture(%{title: "Module A"}, [cat1])
      _m2 = module_with_categories_fixture(%{title: "Module B"}, [cat2])

      result = Modules.list_modules_by_goal_category(cat1.id)
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "returns empty list when no modules match" do
      cat = goal_category_fixture()
      assert Modules.list_modules_by_goal_category(cat.id) == []
    end

    test "returns modules belonging to 2 categories" do
      cat1 = goal_category_fixture(%{name: "Cat 1", slug: "gc-#{System.unique_integer()}"})
      cat2 = goal_category_fixture(%{name: "Cat 2", slug: "gc-#{System.unique_integer()}"})

      module = module_with_categories_fixture(%{title: "Dual Category"}, [cat1, cat2])

      result1 = Modules.list_modules_by_goal_category(cat1.id)
      result2 = Modules.list_modules_by_goal_category(cat2.id)

      assert length(result1) == 1
      assert hd(result1).id == module.id
      assert length(result2) == 1
      assert hd(result2).id == module.id
    end
  end

  describe "list_modules_by_power_pillar/1" do
    test "returns modules with matching power_pillar_1" do
      m1 = module_fixture(%{power_pillar_1: :power_up})
      _m2 = module_fixture(%{power_pillar_1: :power_down})

      result = Modules.list_modules_by_power_pillar(:power_up)
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "returns modules with matching power_pillar_2" do
      m1 = module_fixture(%{power_pillar_1: :power_up, power_pillar_2: :empower})
      _m2 = module_fixture(%{power_pillar_1: :power_down})

      result = Modules.list_modules_by_power_pillar(:empower)
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "returns modules matching either pillar" do
      m1 = module_fixture(%{power_pillar_1: :power_through})
      m2 = module_fixture(%{power_pillar_1: :power_up, power_pillar_2: :power_through})

      result = Modules.list_modules_by_power_pillar(:power_through)
      ids = Enum.map(result, & &1.id) |> Enum.sort()
      assert ids == Enum.sort([m1.id, m2.id])
    end
  end

  describe "filter_modules/1" do
    test "filters by intensity — includes lower intensities" do
      m1 = module_fixture(%{intensity: :high})
      m2 = module_fixture(%{intensity: :low})

      # High includes all: low, moderate, high
      result = Modules.filter_modules(%{intensity: :high})
      ids = Enum.map(result, & &1.id) |> Enum.sort()
      assert ids == Enum.sort([m1.id, m2.id])

      # Low only includes low
      result = Modules.filter_modules(%{intensity: :low})
      assert length(result) == 1
      assert hd(result).id == m2.id
    end

    test "filters by daily_time" do
      m1 = module_fixture(%{daily_time: 30})
      _m2 = module_fixture(%{daily_time: 60})

      result = Modules.filter_modules(%{daily_time: 30})
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "includes modules with nil daily_time" do
      m1 = module_fixture(%{daily_time: nil})
      _m2 = module_fixture(%{daily_time: 60})

      result = Modules.filter_modules(%{daily_time: 30})
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "filters by weekly_freq" do
      m1 = module_fixture(%{weekly_freq: 3})
      _m2 = module_fixture(%{weekly_freq: 5})

      result = Modules.filter_modules(%{weekly_freq: 3})
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "filters by lead_time_fit" do
      m1 = module_fixture(%{lead_time_fit: :short})
      _m2 = module_fixture(%{lead_time_fit: :long})

      result = Modules.filter_modules(%{lead_time_fit: :short})
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "filters by module_type" do
      m1 = module_fixture(%{module_type: :bespoke})
      _m2 = module_fixture(%{module_type: :foundational})

      result = Modules.filter_modules(%{module_type: :bespoke})
      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "combines multiple filters" do
      m1 = module_fixture(%{intensity: :low, lead_time_fit: :short, daily_time: 30})
      _m2 = module_fixture(%{intensity: :low, lead_time_fit: :long, daily_time: 30})
      _m3 = module_fixture(%{intensity: :high, lead_time_fit: :short, daily_time: 30})

      # low intensity + short lead time → only m1 (m3 is high, excluded by low filter)
      result =
        Modules.filter_modules(%{
          intensity: :low,
          lead_time_fit: :short
        })

      assert length(result) == 1
      assert hd(result).id == m1.id
    end

    test "returns all modules with empty criteria" do
      module_fixture()
      module_fixture()

      result = Modules.filter_modules(%{})
      assert length(result) == 2
    end

    test "returns empty list when no modules match" do
      module_fixture(%{intensity: :high})

      result = Modules.filter_modules(%{intensity: :low})
      assert result == []
    end

    test "preloads protocols and goal_categories" do
      module = module_fixture()
      protocol_fixture(module, %{position: 1})

      [loaded] = Modules.filter_modules(%{})
      assert Ecto.assoc_loaded?(loaded.protocols)
      assert Ecto.assoc_loaded?(loaded.goal_categories)
      assert length(loaded.protocols) == 1
    end
  end

  describe "create_protocol/1" do
    test "creates a protocol with valid attrs" do
      module = module_fixture()

      attrs = %{
        module_id: module.id,
        position: 1,
        purpose: "Build strength",
        steps: "Step 1\nStep 2",
        prescription: "3 sets of 10"
      }

      assert {:ok, protocol} = Modules.create_protocol(attrs)
      assert protocol.position == 1
      assert protocol.purpose == "Build strength"
    end

    test "module can have up to 4 protocols" do
      module = module_fixture()

      for pos <- 1..4 do
        assert {:ok, _} =
                 Modules.create_protocol(%{
                   module_id: module.id,
                   position: pos,
                   purpose: "Purpose #{pos}",
                   steps: "Steps #{pos}",
                   prescription: "Prescription #{pos}"
                 })
      end

      assert length(Modules.list_protocols_for_module(module.id)) == 4
    end

    test "module with only 1 protocol" do
      module = module_fixture()

      assert {:ok, _} =
               Modules.create_protocol(%{
                 module_id: module.id,
                 position: 1,
                 purpose: "Solo protocol",
                 steps: "Just one step",
                 prescription: "Once daily"
               })

      assert length(Modules.list_protocols_for_module(module.id)) == 1
    end

    test "enforces unique position per module" do
      module = module_fixture()

      assert {:ok, _} =
               Modules.create_protocol(%{
                 module_id: module.id,
                 position: 1,
                 purpose: "First",
                 steps: "Steps",
                 prescription: "Prescription"
               })

      assert {:error, _} =
               Modules.create_protocol(%{
                 module_id: module.id,
                 position: 1,
                 purpose: "Duplicate",
                 steps: "Steps",
                 prescription: "Prescription"
               })
    end
  end

  describe "list_protocols_for_module/1" do
    test "returns protocols ordered by position" do
      module = module_fixture()
      protocol_fixture(module, %{position: 3})
      protocol_fixture(module, %{position: 1})
      protocol_fixture(module, %{position: 2})

      protocols = Modules.list_protocols_for_module(module.id)
      positions = Enum.map(protocols, & &1.position)
      assert positions == [1, 2, 3]
    end

    test "returns empty list for module with no protocols" do
      module = module_fixture()
      assert Modules.list_protocols_for_module(module.id) == []
    end
  end

  describe "module_completeness/1" do
    test "returns 100% for a complete module" do
      module =
        module_fixture(%{
          overview: "Overview",
          core_concepts: "Concepts",
          power_pillar_1: :power_up,
          outcomes: "Outcomes",
          modifications: "Modifications",
          coach_tip: "Tip",
          intensity: :high,
          daily_time: 30,
          weekly_freq: 3,
          lead_time_fit: :short,
          module_type: :foundational
        })

      {pct, missing} = Modules.module_completeness(module)
      assert pct == 100
      assert missing == []
    end

    test "returns correct percentage for partial module" do
      module = module_fixture(%{overview: nil, core_concepts: nil, outcomes: nil})
      {pct, missing} = Modules.module_completeness(module)
      assert pct < 100
      assert "overview" in missing
      assert "core_concepts" in missing
      assert "outcomes" in missing
    end

    test "returns 0% missing fields for minimal module" do
      module =
        module_fixture(%{
          overview: nil,
          core_concepts: nil,
          outcomes: nil,
          modifications: nil,
          coach_tip: nil,
          daily_time: nil,
          weekly_freq: nil
        })

      {_pct, missing} = Modules.module_completeness(module)
      assert missing != []
    end
  end

  describe "list_contributors/0" do
    test "returns unique contributor names" do
      module_fixture(%{contributor: "Paula V"})
      module_fixture(%{contributor: "Andrea F"})
      module_fixture(%{contributor: "Paula V"})

      contributors = Modules.list_contributors()
      assert contributors == ["Andrea F", "Paula V"]
    end

    test "returns empty list when no modules" do
      assert Modules.list_contributors() == []
    end
  end
end
