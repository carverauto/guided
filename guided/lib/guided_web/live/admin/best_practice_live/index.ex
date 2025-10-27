defmodule GuidedWeb.Admin.BestPracticeLive.Index do
  use GuidedWeb, :live_view

  alias Guided.Graph

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :best_practices, list_best_practices())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Best Practice")
    |> assign(:best_practice, get_best_practice!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Best Practice")
    |> assign(:best_practice, %{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Best Practices")
    |> assign(:best_practice, nil)
  end

  @impl true
  def handle_info({:put_flash, kind, msg}, socket) do
    {:noreply, put_flash(socket, kind, msg)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = Graph.query("MATCH (n:BestPractice) WHERE id(n) = #{id} DETACH DELETE n")

    {:noreply,
     socket
     |> put_flash(:info, "Best practice deleted successfully")
     |> stream(:best_practices, list_best_practices(), reset: true)}
  end

  defp list_best_practices do
    case Graph.query("""
    MATCH (bp:BestPractice)
    RETURN {id: id(bp), name: bp.name, technology: bp.technology, category: bp.category,
            description: bp.description, code_example: bp.code_example}
    ORDER BY bp.name
    """) do
      {:ok, results} ->
        Enum.map(results || [], fn result ->
          %{
            id: result["id"] || 0,
            name: result["name"] || "",
            technology: result["technology"] || "",
            category: result["category"] || "",
            description: result["description"] || "",
            code_example: result["code_example"] || ""
          }
        end)
      {:error, _} -> []
    end
  end

  defp get_best_practice!(id) do
    case Graph.query("""
    MATCH (bp:BestPractice)
    WHERE id(bp) = #{id}
    RETURN {id: id(bp), name: bp.name, technology: bp.technology, category: bp.category,
            description: bp.description, code_example: bp.code_example}
    """) do
      {:ok, [result]} ->
        %{
          id: result["id"] || String.to_integer("#{id}"),
          name: result["name"] || "",
          technology: result["technology"] || "",
          category: result["category"] || "",
          description: result["description"] || "",
          code_example: result["code_example"] || ""
        }
      {:error, _} ->
        %{
          id: String.to_integer("#{id}"),
          name: "",
          technology: "",
          category: "",
          description: "",
          code_example: ""
        }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <.header>
        Best Practices
        <:subtitle>Manage coding best practices in the knowledge graph</:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="text-sm font-semibold text-gray-600 hover:text-gray-900">
            ← Back to Dashboard
          </.link>
          <.link patch={~p"/admin/best_practices/new"}>
            <.button>New Best Practice</.button>
          </.link>
        </:actions>
      </.header>

      <.table
        id="best_practices"
        rows={@streams.best_practices}
        row_click={fn {_id, practice} -> JS.navigate(~p"/admin/best_practices/#{practice.id}/edit") end}
      >
        <:col :let={{_id, practice}} label="Name">{practice.name}</:col>
        <:col :let={{_id, practice}} label="Technology">
          <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-purple-50 text-purple-700 ring-1 ring-inset ring-purple-600/20">
            {practice.technology}
          </span>
        </:col>
        <:col :let={{_id, practice}} label="Category">
          <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20">
            {practice.category}
          </span>
        </:col>
        <:action :let={{_id, practice}}>
          <.link patch={~p"/admin/best_practices/#{practice.id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, practice}}>
          <.link
            phx-click={JS.push("delete", value: %{id: practice.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="best-practice-modal"
        show
        on_cancel={JS.patch(~p"/admin/best_practices")}
      >
        <.live_component
          module={GuidedWeb.Admin.BestPracticeLive.FormComponent}
          id={@best_practice[:id] || :new}
          title={@page_title}
          action={@live_action}
          best_practice={@best_practice}
          patch={~p"/admin/best_practices"}
        />
      </.modal>
    </div>
    """
  end
end
