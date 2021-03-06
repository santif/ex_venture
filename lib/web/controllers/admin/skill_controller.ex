defmodule Web.Admin.SkillController do
  use Web.AdminController

  alias Web.Class
  alias Web.Skill

  def show(conn, %{"id" => id}) do
    skill = Skill.get(id)
    conn |> render("show.html", skill: skill)
  end

  def new(conn, %{"class_id" => class_id}) do
    class = Class.get(class_id)
    changeset = Skill.new(class)
    conn |> render("new.html", class: class, changeset: changeset)
  end

  def create(conn, %{"class_id" => class_id, "skill" => params}) do
    class = Class.get(class_id)
    case Skill.create(class, params) do
      {:ok, skill} -> conn |> redirect(to: skill_path(conn, :show, skill.id))
      {:error, changeset} -> conn |> render("new.html", class: class, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    skill = Skill.get(id)
    changeset = Skill.edit(skill)
    conn |> render("edit.html", skill: skill, changeset: changeset)
  end

  def update(conn, %{"id" => id, "skill" => params}) do
    case Skill.update(id, params) do
      {:ok, skill} -> conn |> redirect(to: skill_path(conn, :show, skill.id))
      {:error, changeset} ->
        skill = Skill.get(id)
        conn |> render("edit.html", skill: skill, changeset: changeset)
    end
  end
end
