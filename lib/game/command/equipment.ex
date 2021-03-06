defmodule Game.Command.Equipment do
  @moduledoc """
  The "equipment" command
  """

  use Game.Command

  alias Game.Items

  commands [{"equipment", ["eq"]}]

  @impl Game.Command
  def help(:topic), do: "Equipment"
  def help(:short), do: "View your character's worn equipment"
  def help(:full) do
    """
    #{help(:short)}. Similar to inventory but
    will only display items worn and wielded.

    Example:
    [ ] > {white}equipment{/white}
    """
  end

  @doc """
  View your character's worn equipment
  """
  @impl Game.Command
  @spec run(args :: [], session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({}, _session, %{socket: socket, save: %{wearing: wearing, wielding: wielding}}) do
    wearing = wearing
    |> Enum.reduce(%{}, fn ({slot, instance}, wearing) ->
      Map.put(wearing, slot, Items.item(instance))
    end)

    wielding = wielding
    |> Enum.reduce(%{}, fn ({hand, instance}, wielding) ->
      Map.put(wielding, hand, Items.item(instance))
    end)

    socket |> @socket.echo(Format.equipment(wearing, wielding))
    :ok
  end
end
