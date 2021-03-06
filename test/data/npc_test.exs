defmodule Data.NPCTest do
  use Data.ModelCase

  alias Data.NPC

  test "validates stats" do
    changeset = %NPC{} |> NPC.changeset(%{})
    assert changeset.errors[:stats]

    changeset = %NPC{} |> NPC.changeset(%{stats: %{}})
    assert changeset.errors[:stats]

    changeset = %NPC{} |> NPC.changeset(%{stats: base_save().stats})
    refute changeset.errors[:stats]
  end

  test "validate effects" do
    changeset = %NPC{} |> NPC.changeset(%{})
    assert changeset.errors[:events]

    changeset = %NPC{} |> NPC.changeset(%{events: []})
    refute changeset.errors[:events]

    changeset = %NPC{} |> NPC.changeset(%{events: [%{type: "room/entered", action: %{type: "say", message: "Hi"}}]})
    refute changeset.errors[:events]

    changeset = %NPC{} |> NPC.changeset(%{events: [%{type: "room/entered"}]})
    assert changeset.errors[:events]
  end

  test "validates status line has a period and a name" do
    changeset = %NPC{} |> NPC.changeset(%{status_line: nil})
    assert changeset.errors[:status_line]

    changeset = %NPC{} |> NPC.changeset(%{status_line: "hi."})
    assert changeset.errors[:status_line]

    changeset = %NPC{} |> NPC.changeset(%{status_line: "{name}"})
    assert changeset.errors[:status_line]
  end
end
