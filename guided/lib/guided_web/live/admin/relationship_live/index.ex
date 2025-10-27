defmodule GuidedWeb.Admin.RelationshipLive.Index do
  use GuidedWeb, :live_view

  alias Guided.Graph

  defp node_types do
    ["Technology", "Vulnerability", "SecurityControl", "BestPractice", "UseCase", "DeploymentPattern"]
  end

  defp relationship_types do
    [
      {"RECOMMENDED_FOR", "recommended_for"},
      {"HAS_VULNERABILITY", "has_vulnerability"},
      {"MITIGATED_BY", "mitigated_by"},
      {"IMPLEMENTS_CONTROL", "implements_control"},
      {"HAS_BEST_PRACTICE", "has_best_practice"},
      {"RECOMMENDED_DEPLOYMENT", "recommended_deployment"},
      {"REQUIRES", "requires"},
      {"CONFLICTS_WITH", "conflicts_with"}
    ]
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:relationships, list_relationships())
     |> assign(:show_form, false)
     |> assign(:from_type, "Technology")
     |> assign(:to_type, "Vulnerability")
     |> assign(:relationship_type, "has_vulnerability")
     |> assign(:from_nodes, list_nodes_by_type("Technology"))
     |> assign(:to_nodes, list_nodes_by_type("Vulnerability"))
     |> assign(:selected_from_id, nil)
     |> assign(:selected_to_id, nil)}
  end

  @impl true
  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, :show_form, !socket.assigns.show_form)}
  end

  @impl true
  def handle_event("from_type_changed", %{"from_type" => from_type}, socket) do
    {:noreply,
     socket
     |> assign(:from_type, from_type)
     |> assign(:from_nodes, list_nodes_by_type(from_type))
     |> assign(:selected_from_id, nil)}
  end

  @impl true
  def handle_event("to_type_changed", %{"to_type" => to_type}, socket) do
    {:noreply,
     socket
     |> assign(:to_type, to_type)
     |> assign(:to_nodes, list_nodes_by_type(to_type))
     |> assign(:selected_to_id, nil)}
  end

  @impl true
  def handle_event("from_node_changed", %{"from_id" => from_id}, socket) do
    {:noreply, assign(socket, :selected_from_id, from_id)}
  end

  @impl true
  def handle_event("to_node_changed", %{"to_id" => to_id}, socket) do
    {:noreply, assign(socket, :selected_to_id, to_id)}
  end

  @impl true
  def handle_event("rel_type_changed", %{"rel_type" => rel_type}, socket) do
    {:noreply, assign(socket, :relationship_type, rel_type)}
  end

  @impl true
  def handle_event("create_relationship", _params, socket) do
    from_id = socket.assigns.selected_from_id
    to_id = socket.assigns.selected_to_id
    rel_type = socket.assigns.relationship_type |> String.upcase()

    if from_id && to_id do
      query = """
      MATCH (from), (to)
      WHERE id(from) = #{from_id} AND id(to) = #{to_id}
      CREATE (from)-[r:#{rel_type}]->(to)
      RETURN id(r)
      """

      case Graph.query(query) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "Relationship created successfully")
           |> assign(:relationships, list_relationships())
           |> assign(:show_form, false)
           |> assign(:selected_from_id, nil)
           |> assign(:selected_to_id, nil)}

        {:error, _error} ->
          {:noreply, put_flash(socket, :error, "Error creating relationship")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select both source and target nodes")}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    query = """
    MATCH ()-[r]->()
    WHERE id(r) = #{id}
    DELETE r
    """

    case Graph.query(query) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Relationship deleted successfully")
         |> assign(:relationships, list_relationships())}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error deleting relationship")}
    end
  end

  defp list_relationships do
    case Graph.query("""
    MATCH (from)-[r]->(to)
    RETURN {id: id(r), from_label: labels(from)[0], from_name: from.name,
            rel_type: type(r), to_label: labels(to)[0], to_name: to.name}
    """) do
      {:ok, results} ->
        results
        |> Enum.map(fn result ->
          %{
            id: result["id"],
            from_label: result["from_label"] || "",
            from_name: result["from_name"] || "Unnamed",
            rel_type: result["rel_type"] || "",
            to_label: result["to_label"] || "",
            to_name: result["to_name"] || "Unnamed"
          }
        end)
        |> Enum.sort_by(& &1.rel_type)

      {:error, _} ->
        []
    end
  end

  defp list_nodes_by_type(node_type) do
    case Graph.query("""
    MATCH (n:#{node_type})
    RETURN {id: id(n), name: n.name}
    ORDER BY n.name
    """) do
      {:ok, results} ->
        Enum.map(results || [], fn result ->
          id = result["id"] || 0
          name = result["name"] || "Unnamed (#{id})"
          {name, id}
        end)

      {:error, _} ->
        []
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <.header>
        Relationships
        <:subtitle>Manage relationships (edges) between nodes in the knowledge graph</:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="text-sm font-semibold text-gray-600 hover:text-gray-900">
            ← Back to Dashboard
          </.link>
          <.button phx-click="toggle_form">
            <%= if @show_form, do: "Cancel", else: "New Relationship" %>
          </.button>
        </:actions>
      </.header>

      <%= if @show_form do %>
        <div class="mt-8 mb-8 bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Create New Relationship</h3>

          <div class="grid grid-cols-1 gap-6 md:grid-cols-3">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Source Node Type</label>
              <select
                phx-change="from_type_changed"
                name="from_type"
                class="w-full bg-white border border-gray-300 text-gray-900 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 px-3 py-2"
              >
                <%= for type <- node_types() do %>
                  <option value={type} selected={@from_type == type}>{type}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Relationship Type</label>
              <select
                phx-change="rel_type_changed"
                name="rel_type"
                class="w-full bg-white border border-gray-300 text-gray-900 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 px-3 py-2"
              >
                <%= for {label, value} <- relationship_types() do %>
                  <option value={value} selected={@relationship_type == value}>{label}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Target Node Type</label>
              <select
                phx-change="to_type_changed"
                name="to_type"
                class="w-full bg-white border border-gray-300 text-gray-900 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 px-3 py-2"
              >
                <%= for type <- node_types() do %>
                  <option value={type} selected={@to_type == type}>{type}</option>
                <% end %>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-6 md:grid-cols-2 mt-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Source Node</label>
              <select
                phx-change="from_node_changed"
                name="from_id"
                class="w-full bg-white border border-gray-300 text-gray-900 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 px-3 py-2"
              >
                <option value="">-- Select {String.downcase(@from_type)} --</option>
                <%= for {name, id} <- @from_nodes do %>
                  <option value={id} selected={@selected_from_id == to_string(id)}>{name}</option>
                <% end %>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Target Node</label>
              <select
                phx-change="to_node_changed"
                name="to_id"
                class="w-full bg-white border border-gray-300 text-gray-900 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 px-3 py-2"
              >
                <option value="">-- Select {String.downcase(@to_type)} --</option>
                <%= for {name, id} <- @to_nodes do %>
                  <option value={id} selected={@selected_to_id == to_string(id)}>{name}</option>
                <% end %>
              </select>
            </div>
          </div>

          <div class="mt-6">
            <.button phx-click="create_relationship" disabled={!@selected_from_id || !@selected_to_id}>
              Create Relationship
            </.button>
          </div>
        </div>
      <% end %>

      <.table id="relationships" rows={@relationships}>
        <:col :let={rel} label="Source">
          <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-purple-50 text-purple-700 ring-1 ring-inset ring-purple-600/20">
            {rel.from_label}
          </span>
          <span class="ml-2 text-sm font-medium text-gray-900">{rel.from_name}</span>
        </:col>
        <:col :let={rel} label="Relationship">
          <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20">
            {rel.rel_type}
          </span>
        </:col>
        <:col :let={rel} label="Target">
          <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20">
            {rel.to_label}
          </span>
          <span class="ml-2 text-sm font-medium text-gray-900">{rel.to_name}</span>
        </:col>
        <:action :let={rel}>
          <.link phx-click={JS.push("delete", value: %{id: rel.id})} data-confirm="Are you sure?">
            Delete
          </.link>
        </:action>
      </.table>
    </div>
    """
  end
end
