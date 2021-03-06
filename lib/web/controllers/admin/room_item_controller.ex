defmodule Web.Admin.RoomItemController do
  use Web.AdminController

  alias Web.Item
  alias Web.Room

  def new(conn, %{"room_id" => room_id, "spawn" => "false"}) do
    room = Room.get(room_id)
    conn |> render("add-item.html", items: Item.all(), room: room)
  end
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)
    changeset = Room.new_item(room)
    conn |> render("new.html", items: Item.all(), room: room, changeset: changeset)
  end

  def create(conn, %{"room_id" => room_id, "item" => %{"id" => item_id}}) do
    room = Room.get(room_id)
    case Room.add_item(room, item_id) do
      {:ok, room} -> conn |> redirect(to: room_path(conn, :show, room.id))
      {:error, _changeset} -> conn |> render("add-item.html", items: Item.all(), room: room)
    end
  end
  def create(conn, %{"room_id" => room_id, "room_item" => params}) do
    room = Room.get(room_id)
    case Room.create_item(room, params) do
      {:ok, room_item} -> conn |> redirect(to: room_path(conn, :show, room_item.room_id))
      {:error, changeset} -> conn |> render("new.html", items: Item.all(), room: room, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Room.delete_item(id) do
      {:ok, room_item} ->
        conn |> redirect(to: room_path(conn, :show, room_item.room_id))
      _ ->
        conn |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
