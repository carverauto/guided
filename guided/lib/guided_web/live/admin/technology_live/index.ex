defmodule GuidedWeb.Admin.TechnologyLive.Index do
  use GuidedWeb, :live_view

  alias Guided.Graph

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :technologies, list_technologies())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Technology")
    |> assign(:technology, get_technology!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Technology")
    |> assign(:technology, %{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Technologies")
    |> assign(:technology, nil)
  end

  @impl true
  def handle_info({:put_flash, kind, msg}, socket) do
    {:noreply, put_flash(socket, kind, msg)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    # Delete the technology node
    {:ok, _} = Graph.query("MATCH (n:Technology) WHERE id(n) = #{id} DETACH DELETE n")

    {:noreply,
     socket
     |> put_flash(:info, "Technology deleted successfully")
     |> stream(:technologies, list_technologies(), reset: true)}
  end

  defp list_technologies do
    # Query all technologies with their ID and properties as a single map
    case Graph.query("""
    MATCH (t:Technology)
    RETURN {id: id(t), name: t.name, category: t.category, version: t.version,
            maturity: t.maturity, security_rating: t.security_rating, description: t.description}
    ORDER BY t.name
    """) do
      {:ok, results} ->
        Enum.map(results || [], fn result ->
          %{
            id: result["id"] || 0,
            name: result["name"] || "",
            category: result["category"] || "",
            version: result["version"] || "",
            maturity: result["maturity"] || "",
            security_rating: result["security_rating"] || "",
            description: result["description"] || ""
          }
        end)
      {:error, _} -> []
    end
  end

  defp get_technology!(id) do
    # Query for a single technology by ID
    case Graph.query("""
    MATCH (t:Technology)
    WHERE id(t) = #{id}
    RETURN {id: id(t), name: t.name, category: t.category, version: t.version,
            maturity: t.maturity, security_rating: t.security_rating, description: t.description}
    """) do
      {:ok, [result]} ->
        %{
          id: result["id"] || String.to_integer("#{id}"),
          name: result["name"] || "",
          category: result["category"] || "",
          version: result["version"] || "",
          maturity: result["maturity"] || "",
          security_rating: result["security_rating"] || "",
          description: result["description"] || ""
        }
      {:error, _} ->
        %{
          id: String.to_integer("#{id}"),
          name: "",
          category: "",
          version: "",
          maturity: "",
          security_rating: "",
          description: ""
        }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <.header>
        Technologies
        <:subtitle>Manage technologies in the knowledge graph</:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="text-sm font-semibold text-gray-600 hover:text-gray-900">
            ← Back to Dashboard
          </.link>
          <.link patch={~p"/admin/technologies/new"}>
            <.button>New Technology</.button>
          </.link>
        </:actions>
      </.header>

      <.table
        id="technologies"
        rows={@streams.technologies}
        row_click={fn {_id, technology} -> JS.navigate(~p"/admin/technologies/#{technology.id}/edit") end}
      >
        <:col :let={{_id, technology}} label="Name">{technology.name}</:col>
        <:col :let={{_id, technology}} label="Category">{technology.category}</:col>
        <:col :let={{_id, technology}} label="Version">{technology.version}</:col>
        <:col :let={{_id, technology}} label="Maturity">
          <span class={"inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{maturity_color(technology.maturity)}"}>
            {technology.maturity}
          </span>
        </:col>
        <:col :let={{_id, technology}} label="Security">
          <span class={"inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{security_color(technology.security_rating)}"}>
            {technology.security_rating}
          </span>
        </:col>
        <:action :let={{_id, technology}}>
          <.link patch={~p"/admin/technologies/#{technology.id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, technology}}>
          <.link
            phx-click={JS.push("delete", value: %{id: technology.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="technology-modal"
        show
        on_cancel={JS.patch(~p"/admin/technologies")}
      >
        <.live_component
          module={GuidedWeb.Admin.TechnologyLive.FormComponent}
          id={@technology[:id] || :new}
          title={@page_title}
          action={@live_action}
          technology={@technology}
          patch={~p"/admin/technologies"}
        />
      </.modal>
    </div>
    """
  end

  defp maturity_color("mature"), do: "bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20"
  defp maturity_color("stable"), do: "bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20"
  defp maturity_color(_), do: "bg-yellow-50 text-yellow-700 ring-1 ring-inset ring-yellow-600/20"

  defp security_color("excellent"), do: "bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20"
  defp security_color("good"), do: "bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20"
  defp security_color(_), do: "bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20"
end
