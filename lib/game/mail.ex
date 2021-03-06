defmodule Game.Mail do
  @moduledoc """
  Helpers for dealing with the mail system
  """

  import Ecto.Query

  alias Data.Mail
  alias Data.Repo
  alias Data.User

  @doc """
  Get mail for a user
  """
  @spec unread_mail_for(User.t()) :: [Mail.t()]
  def unread_mail_for(user) do
    Mail
    |> where([m], m.is_read == false)
    |> where([m], m.receiver_id == ^user.id)
    |> preload([:sender])
    |> Repo.all()
  end

  @doc """
  Get mail for a user
  """
  @spec get(User.t(), integer()) :: Mail.t() | nil
  def get(receiver, id) do
    Mail
    |> Repo.get_by(receiver_id: receiver.id, id: id)
    |> Repo.preload([:sender])
  end

  @doc """
  Mark a piece of mail as read
  """
  @spec mark_read!(Mail.t()) :: {:ok, Mail.t()}
  def mark_read!(mail) do
    mail
    |> Mail.changeset(%{is_read: true})
    |> Repo.update()
  end
end
