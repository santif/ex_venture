defmodule Game.Command.Wield do
  @moduledoc """
  The "wield" command
  """

  use Game.Command

  alias Game.Item
  alias Game.Items

  @must_be_alive true

  commands ["wield", "unwield"], parse: false

  @impl Game.Command
  def help(:topic), do: "Wield"
  def help(:short), do: "Put an item in your hands"
  def help(:full) do
    """
    Put an item from your inventory into your left or right hand.
    The default hand is your right hand. You can only wield one weapon.

    Example:
    [ ] > {white}wield [left|right] sword{/white}
    [ ] > {white}unwield [left|right]{/white}
    """
  end

  @impl Game.Command
  @doc """
  Parse the command to determine wield or unwield

      iex> Game.Command.Wield.parse("wield right sword")
      {:wield, "right sword"}

      iex> Game.Command.Wield.parse("unwield right sword")
      {:unwield, "right sword"}

      iex> Game.Command.Wield.parse("unweld right sword")
      {:error, :bad_parse, "unweld right sword"}
  """
  @spec parse(command :: String.t) :: []
  def parse("wield " <> command), do: {:wield, command}
  def parse("unwield " <> command), do: {:unwield, command}
  def parse(command), do: {:error, :bad_parse, command}

  @doc """
  Put an item in your hands
  """
  @impl Game.Command
  @spec run(args :: {atom, String.t}, session :: Session.t, state :: map) :: :ok
  def run(command, session, state)
  def run({:wield, item_name}, _session, state = %{socket: socket, save: %{items: items}}) do
    {hand, item_name} = pick_hand(item_name)

    items = Items.items(items)
    case Item.find_item(items, item_name) do
      nil -> socket |> item_not_found(item_name)
      item -> socket |> item_found(hand, item, state)
    end
  end
  def run({:unwield, hand}, _session, state = %{socket: socket}) do
    case hand do
      "right" -> run_unwield(:right, state)
      "left" -> run_unwield(:left, state)
      _ ->
        socket |> @socket.echo("Unknown hand")
        :ok
    end
  end

  defp item_not_found(socket, item_name) do
    socket |> @socket.echo(~s("#{item_name}" could not be found."))
    :ok
  end

  # Unwield the current item in your hand, adding to inventory
  # Wield the new item, removing from inventory
  defp item_found(socket, _, item = %{level: item_level, type: "weapon"}, %{save: %{level: level}}) when level < item_level do
    socket |> @socket.echo("You cannot wield \"#{Format.item_name(item)}\", you are not high enough level.")
    :ok
  end
  defp item_found(socket, hand, item = %{type: "weapon"}, state) do
    %{save: save} = state
    %{items: items} = save

    {wielding, items} =  unwield(hand, save.wielding, items)
    {wielding, items} =  unwield(opposite_hand(hand), wielding, items)
    {instance, items} = Item.remove(items, item)
    wielding = Map.put(wielding, hand, instance)
    save = %{save | items: items, wielding: wielding}

    socket |> @socket.echo(~s(#{item.name} is now in your #{hand} hand.))
    {:update, Map.put(state, :save, save)}
  end
  defp item_found(socket, _, item, _state) do
    socket |> @socket.echo(~s(#{item.name} cannot be wielded))
    :ok
  end

  defp run_unwield(hand, state) do
    %{save: save, socket: socket} = state
    %{items: items} = save

    {wielding, items} =  unwield(hand, save.wielding, items)
    save = %{save | items: items, wielding: wielding}
    socket |> @socket.echo(~s(Your #{hand} hand is now empty.))
    {:update, Map.put(state, :save, save)}
  end

  @doc """
  Determine which hand is being used from the item string

  Examples:

      iex> Game.Command.Wield.pick_hand("sword")
      {:right, "sword"}

      iex> Game.Command.Wield.pick_hand("right sword")
      {:right, "sword"}

      iex> Game.Command.Wield.pick_hand("left sword")
      {:left, "sword"}
  """
  @spec pick_hand(item_string :: String.t) :: {:right, String.t} | {:left, String.t}
  def pick_hand("left " <> item), do: {:left, item}
  def pick_hand("right " <> item), do: {:right, item}
  def pick_hand(item), do: {:right, item}

  @doc """
  Get the opposite hand

  Examples:

      iex> Game.Command.Wield.opposite_hand("left")
      iex> Game.Command.Wield.opposite_hand(:left)
      :right

      iex> Game.Command.Wield.opposite_hand("right")
      iex> Game.Command.Wield.opposite_hand(:right)
      :left
  """
  @spec opposite_hand(hand :: String.t | atom()) :: :right | :left
  def opposite_hand("left"), do: :right
  def opposite_hand(:left), do: :right
  def opposite_hand("right"), do: :left
  def opposite_hand(:right), do: :left

  @doc """
  Remove an item from your hand and place back into the inventory

  Examples:

      iex> Game.Command.Wield.unwield(:right, %{right: 1}, [])
      {%{}, [1]}
      iex> Game.Command.Wield.unwield(:right, %{right: 1, left: 2}, [3])
      {%{left: 2}, [1, 3]}

      iex> Game.Command.Wield.unwield(:left, %{left: 1}, [])
      {%{}, [1]}
      iex> Game.Command.Wield.unwield(:left, %{right: 1, left: 2}, [3])
      {%{right: 1}, [2, 3]}

      iex> Game.Command.Wield.unwield(:right, %{}, [])
      {%{}, []}
      iex> Game.Command.Wield.unwield(:right, %{left: 1}, [])
      {%{left: 1}, []}

      iex> Game.Command.Wield.unwield(:left, %{}, [])
      {%{}, []}
      iex> Game.Command.Wield.unwield(:left, %{right: 1}, [])
      {%{right: 1}, []}

      iex> Game.Command.Wield.unwield(:right, nil, [])
      {%{}, []}
      iex> Game.Command.Wield.unwield(:left, nil, [])
      {%{}, []}
  """
  @spec unwield(hand :: atom, wielding :: map, items :: [Item.instance()]) :: {wielding :: map, inventory :: [Item.instance()]}
  def unwield(hand, wielding, items)
  def unwield(:right, wielding = %{right: instance}, items) do
    wielding = Map.delete(wielding, :right)
    {wielding, [instance | items]}
  end
  def unwield(:left, wielding = %{left: instance}, items) do
    wielding = Map.delete(wielding, :left)
    {wielding, [instance | items]}
  end
  def unwield(_hand, nil, items), do: {%{}, items}
  def unwield(_hand, wielding, items), do: {wielding, items}
end
