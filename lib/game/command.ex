defmodule Game.Command do
  @moduledoc """
  Parses and runs commands from players
  """

  use Networking.Socket
  use Game.Room

  alias Game.Account
  alias Game.Format
  alias Game.Help
  alias Game.Message
  alias Game.Session

  def parse(command) do
    case command do
      "e" -> {:east}
      "east" -> {:east}
      "global " <> message -> {:global, message}
      "help " <> topic -> {:help, topic |> String.downcase}
      "help" -> {:help}
      "look" -> {:look}
      "n" -> {:north}
      "north" -> {:north}
      "quit" -> {:quit}
      "s" -> {:south}
      "say " <> message -> {:say, message}
      "south" -> {:south}
      "w" -> {:west}
      "west" -> {:west}
      "who" <> _extra -> {:who}
      _ -> {:error, :bad_parse}
    end
  end

  def run({:east}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{east_id: nil} -> :ok
        %{east_id: id} -> session |> move_to(state, id)
      end
    end)
  end

  def run({:global, message}, session, %{socket: socket, user: user}) do
    message = ~s({red}[global]{/red} {blue}#{user.username}{/blue} says, {green}"#{message}"{/green})

    socket |> @socket.echo(message)

    Session.Registry.connected_players()
    |> Enum.reject(&(elem(&1, 0) == session)) # don't send to your own
    |> Enum.map(fn ({session, _user}) ->
      Session.echo(session, message)
    end)

    :ok
  end

  def run({:help}, _session, %{socket: socket}) do
    socket |> @socket.echo(Help.base)
    :ok
  end
  def run({:help, topic}, _session, %{socket: socket}) do
    socket |> @socket.echo(Help.topic(topic))
    :ok
  end

  def run({:look}, _session, %{socket: socket, save: %{room_id: room_id}}) do
    room = @room.look(room_id)
    socket |> @socket.echo(Format.room(room))
    :ok
  end

  def run({:north}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn () ->
      room = @room.look(room_id)
      case room do
        %{north_id: nil} -> :ok
        %{north_id: id} -> session |> move_to(state, id)
      end
    end)
  end

  def run({:quit}, session, %{socket: socket, user: user, save: save}) do
    socket |> @socket.echo("Good bye.")
    socket |> @socket.disconnect

    @room.leave(save.room_id, {:user, session, user})
    user |> Account.save(save)

    :ok
  end

  def run({:say, message}, session, %{socket: socket, user: user, save: %{room_id: room_id}}) do
    socket |> @socket.echo(Format.say(user, message))
    room_id |> @room.say(session, Message.new(user, message))
    :ok
  end

  def run({:south}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{south_id: nil} -> :ok
        %{south_id: id} -> session |> move_to(state, id)
      end
    end)
  end

  def run({:west}, session, state = %{save: %{room_id: room_id}}) do
    speed_check(state, fn() ->
      room = @room.look(room_id)
      case room do
        %{west_id: nil} -> :ok
        %{west_id: id} -> session |> move_to(state, id)
      end
    end)
  end

  def run({:who}, _session, %{socket: socket}) do
    usernames = Session.Registry.connected_players()
    |> Enum.map(fn ({_pid, user}) ->
      "  - {blue}#{user.username}{/blue}\n"
    end)
    |> Enum.join("")

    socket |> @socket.echo("Players online:\n#{usernames}")
    :ok
  end

  def run({:error, :bad_parse}, _session, %{socket: socket}) do
    socket |> @socket.echo("Unknown command")
    :ok
  end

  defp speed_check(state = %{socket: socket}, fun) do
    case Timex.after?(state.last_tick, state.last_move) do
      true ->
        fun.()
      false ->
        socket |> @socket.echo("Slow down.")
        :ok
    end
  end

  defp move_to(session, state = %{save: save, user: user}, room_id) do
    @room.leave(save.room_id, {:user, session, user})

    save = %{save | room_id: room_id}
    state = %{state | save: save, last_move: Timex.now()}

    @room.enter(room_id, {:user, session, user})

    run({:look}, session, state)
    {:update, state}
  end
end
