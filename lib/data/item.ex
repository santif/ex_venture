defmodule Data.Item do
  @moduledoc """
  Item Schema
  """

  use Data.Schema

  alias Data.Effect
  alias __MODULE__
  alias Data.Item.Instance
  alias Data.ItemAspecting
  alias Data.NPCItem
  alias Data.ShopItem
  alias Data.Stats

  @type instance :: %Instance{}

  @types ["basic", "weapon", "armor"]

  @valid_effects %{
    "basic" => ["recover"],
    "weapon" => ["damage", "damage/type", "stats"],
    "armor" => ["stats"],
  }

  @fields [
    :level, :name, :description, :type, :tags, :keywords, :stats, :effects,
    :cost, :user_text, :usee_text, :is_usable, :amount,
  ]

  schema "items" do
    field :name, :string
    field :description, :string
    field :type, :string
    field :tags, {:array, :string}, default: []
    field :keywords, {:array, :string}
    field :stats, Data.Stats
    field :effects, {:array, Data.Effect}
    field :cost, :integer, default: 0
    field :level, :integer, default: 1
    field :user_text, :string, default: "You use {name} on {target}."
    field :usee_text, :string, default: "{user} uses {name} on you."
    field :is_usable, :boolean, default: false
    field :amount, :integer, default: 1

    has_many :item_aspectings, ItemAspecting
    has_many :item_aspects, through: [:item_aspectings, :item_aspect]
    has_many :npc_items, NPCItem
    has_many :shop_items, ShopItem

    timestamps()
  end

  defdelegate compile(item), to: Item.Compiled

  @doc """
  List out item types
  """
  @spec types() :: [String.t]
  def types(), do: @types

  @doc """
  List out item fields
  """
  @spec fields() :: [atom()]
  def fields(), do: @fields

  @doc """
  Provide a starting point for the web panel to edit new statistics
  """
  @spec basic_stats(type :: atom) :: map
  def basic_stats(:armor) do
    %{
      slot: "",
      armor: 0,
    }
  end
  def basic_stats(:basic), do: %{}
  def basic_stats(:weapon), do: %{}

  @doc """
  Create an instance of an item
  """
  @spec instantiate(item :: t()) :: instance()
  def instantiate(item) do
    case item.is_usable do
      true ->
        %Instance{id: item.id, created_at: Timex.now(), amount: item.amount}
      false ->
        %Instance{id: item.id, created_at: Timex.now()}
    end
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @fields)
    |> ensure_keywords
    |> validate_required(@fields)
    |> validate_inclusion(:type, @types)
    |> validate_stats()
    |> Effect.validate_effects()
    |> validate_effects()
  end

  defp ensure_keywords(changeset) do
    case changeset do
      %{changes: %{keywords: _keywords}} -> changeset
      %{data: %{keywords: keywords}} when keywords != nil -> changeset
      _ -> put_change(changeset, :keywords, [])
    end
  end

  @doc """
  Validate item statistics
  """
  @spec validate_stats(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_stats(changeset) do
    case get_change(changeset, :stats) do
      nil -> changeset
      stats -> _validate_stats(changeset, stats)
    end
  end

  defp _validate_stats(changeset, stats) do
    type = get_field(changeset, :type)
    case Stats.valid?(type, stats) do
      true -> changeset
      false -> add_error(changeset, :stats, "are invalid")
    end
  end

  @doc """
  Validate effects are for the proper item type
  """
  @spec validate_effects(changeset :: Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate_effects(changeset) do
    case get_change(changeset, :effects) do
      nil -> changeset
      effects -> _validate_effects(changeset, effects)
    end
  end

  defp _validate_effects(changeset, effects) do
    type = get_field(changeset, :type)
    case effects |> Enum.all?(&(&1.kind in @valid_effects[type])) do
      true -> changeset
      false -> add_error(changeset, :effects, "can only include damage or stats effects")
    end
  end
end
