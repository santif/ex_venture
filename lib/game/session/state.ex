defmodule Game.Session.State do
  @moduledoc """
  Create a struct for Session state
  """

  alias Game.Session.SessionStats

  @type t :: %__MODULE__{}

  @doc """
  Session state storage

  - `:socket` - Socket process pid
  - `:state` - State of the session, `login`, `create`, `active`
  - `:mode` - Mode that the session is in, `commands`, `editor`
  - `:session_started_at` - Timestamp of when the session started
  - `:user` - User struct
  - `:save` - Save struct from the user
  - `:last_recv` - Timestamp of when the session last received a message
  - `:last_tick` - Timestamp of when the session last received a tick
  - `:target` - Target of the user
  - `:is_targeting` - MapSet of who is targeting the user
  - `:regen` - Regen timestamps
  - `:reply_to` - User who the player should respond to
  - `:commands` - Temporary command storage, for continuing, editing, etc
  - `:continuous_effects` - Continuous effects that the user has, list
  """
  @enforce_keys [:socket, :state, :mode]
  defstruct [
    :socket,
    :state,
    :session_started_at,
    :user,
    :save,
    :last_recv,
    :last_tick,
    :target,
    :is_targeting,
    :regen,
    :reply_to,
    :commands,
    mode: "comands",
    continuous_effects: [],
    stats: %SessionStats{},
  ]
end
