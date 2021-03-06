defmodule Web.Admin.NPCItemController do
  use Web.AdminController

  alias Web.Item
  alias Web.NPC

  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.new_item(npc)
    conn |> render("new.html", items: Item.all(), npc: npc, changeset: changeset)
  end

  def create(conn, %{"npc_id" => npc_id, "npc_item" => params}) do
    npc = NPC.get(npc_id)
    case NPC.add_item(npc, params) do
      {:ok, npc_item} -> conn |> redirect(to: npc_path(conn, :show, npc_item.npc_id))
      {:error, changeset} ->
        conn |> render("new.html", items: Item.all(), npc: npc, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    npc_item = NPC.get_item(id)
    npc = NPC.get(npc_item.npc_id)
    changeset = NPC.edit_item(npc_item)
    conn |> render("edit.html", items: Item.all(), npc_item: npc_item, npc: npc, changeset: changeset)
  end

  def update(conn, %{"id" => id, "npc_item" => params}) do
    case NPC.update_item(id, params) do
      {:ok, npc_item} -> conn |> redirect(to: npc_path(conn, :show, npc_item.npc_id))
      {:error, changeset} ->
        npc_item = NPC.get_item(id)
        npc = NPC.get(npc_item.npc_id)
        conn |> render("edit.html", items: Item.all(), npc_item: npc_item, npc: npc, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    case NPC.delete_item(id) do
      {:ok, npc_item} ->
        conn |> redirect(to: npc_path(conn, :show, npc_item.npc_id))
      _ ->
        npc_item = NPC.get_item(id)
        conn |> redirect(to: npc_path(conn, :show, npc_item.npc_id))
    end
  end
end
