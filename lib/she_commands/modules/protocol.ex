defmodule SheCommands.Modules.Protocol do
  @moduledoc """
  Schema for module protocols.

  Each module can have up to 4 protocols, ordered by position.
  Protocols contain the actionable steps and prescriptions that
  form the core of each module's execution plan.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SheCommands.Modules.Module

  schema "protocols" do
    belongs_to :module, Module

    field :position, :integer
    field :purpose, :string
    field :steps, :string
    field :prescription, :string
    field :expected_outcome, :string

    timestamps(type: :utc_datetime)
  end

  @required_fields [:module_id, :position, :purpose, :steps, :prescription]
  @optional_fields [:expected_outcome]

  def changeset(protocol, attrs) do
    protocol
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:position, 1..4)
    |> foreign_key_constraint(:module_id)
    |> unique_constraint([:module_id, :position])
  end
end
