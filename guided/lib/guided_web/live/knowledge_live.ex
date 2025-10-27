defmodule GuidedWeb.KnowledgeLive do
  use GuidedWeb, :live_view

  alias Guided.Graph

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Knowledge Base")
     |> assign(:selected_type, "all")
     |> assign(:search_query, "")
     |> assign(:node, nil)
     |> assign(:relationships, [])
     |> load_stats()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Knowledge Base")
    |> assign(:node, nil)
    |> load_nodes()
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    node = get_node_by_id(id)
    relationships = get_node_relationships(id)

    socket
    |> assign(:page_title, "#{node.name} - Knowledge Base")
    |> assign(:node, node)
    |> assign(:relationships, relationships)
  end

  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:selected_type, type)
     |> load_nodes()}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> load_nodes()}
  end

  defp load_stats(socket) do
    tech_count = get_count("Technology")
    vuln_count = get_count("Vulnerability")
    control_count = get_count("SecurityControl")
    practice_count = get_count("BestPractice")

    socket
    |> assign(:tech_count, tech_count)
    |> assign(:vuln_count, vuln_count)
    |> assign(:control_count, control_count)
    |> assign(:practice_count, practice_count)
  end

  defp get_count(label) do
    case Graph.query("MATCH (n:#{label}) RETURN count(n)") do
      {:ok, [count]} -> count
      _ -> 0
    end
  end

  defp load_nodes(socket) do
    type = socket.assigns.selected_type
    query = socket.assigns.search_query

    nodes = case type do
      "all" -> load_all_nodes(query)
      "Technology" -> load_typed_nodes("Technology", query)
      "Vulnerability" -> load_typed_nodes("Vulnerability", query)
      "SecurityControl" -> load_typed_nodes("SecurityControl", query)
      "BestPractice" -> load_typed_nodes("BestPractice", query)
      _ -> []
    end

    assign(socket, :nodes, nodes)
  end

  defp load_all_nodes(search_query) do
    types = ["Technology", "Vulnerability", "SecurityControl", "BestPractice"]

    Enum.flat_map(types, fn type ->
      load_typed_nodes(type, search_query)
    end)
  end

  defp load_typed_nodes(type, search_query) do
    query_str = if search_query == "" do
      """
      MATCH (n:#{type})
      RETURN {id: id(n), type: labels(n)[0], name: n.name, properties: properties(n)}
      ORDER BY n.name
      LIMIT 50
      """
    else
      # Simple case-insensitive search on name
      search_lower = String.downcase(search_query)
      """
      MATCH (n:#{type})
      WHERE toLower(n.name) CONTAINS '#{escape_cypher_string(search_lower)}'
      RETURN {id: id(n), type: labels(n)[0], name: n.name, properties: properties(n)}
      ORDER BY n.name
      LIMIT 50
      """
    end

    case Graph.query(query_str) do
      {:ok, results} ->
        Enum.map(results, fn result ->
          %{
            id: result["id"],
            type: result["type"],
            name: result["name"],
            properties: result["properties"] || %{}
          }
        end)
      {:error, _} -> []
    end
  end

  defp escape_cypher_string(str) do
    String.replace(str, "'", "\\'")
  end

  defp get_node_by_id(id) do
    query = """
    MATCH (n)
    WHERE id(n) = #{id}
    RETURN {id: id(n), type: labels(n)[0], name: n.name, properties: properties(n)}
    """

    case Graph.query(query) do
      {:ok, [result]} ->
        %{
          id: result["id"],
          type: result["type"],
          name: result["name"],
          properties: result["properties"] || %{}
        }
      _ ->
        %{id: id, type: "Unknown", name: "Not Found", properties: %{}}
    end
  end

  defp get_node_relationships(id) do
    # Get outgoing relationships
    outgoing_query = """
    MATCH (n)-[r]->(target)
    WHERE id(n) = #{id}
    RETURN {
      direction: 'outgoing',
      type: type(r),
      target_id: id(target),
      target_type: labels(target)[0],
      target_name: target.name,
      target_properties: properties(target)
    }
    """

    # Get incoming relationships
    incoming_query = """
    MATCH (source)-[r]->(n)
    WHERE id(n) = #{id}
    RETURN {
      direction: 'incoming',
      type: type(r),
      source_id: id(source),
      source_type: labels(source)[0],
      source_name: source.name,
      source_properties: properties(source)
    }
    """

    outgoing = case Graph.query(outgoing_query) do
      {:ok, results} ->
        Enum.map(results, fn r ->
          %{
            direction: r["direction"],
            type: r["type"],
            node: %{
              id: r["target_id"],
              type: r["target_type"],
              name: r["target_name"],
              properties: r["target_properties"] || %{}
            }
          }
        end)
      _ -> []
    end

    incoming = case Graph.query(incoming_query) do
      {:ok, results} ->
        Enum.map(results, fn r ->
          %{
            direction: r["direction"],
            type: r["type"],
            node: %{
              id: r["source_id"],
              type: r["source_type"],
              name: r["source_name"],
              properties: r["source_properties"] || %{}
            }
          }
        end)
      _ -> []
    end

    outgoing ++ incoming
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @node do %>
      <.node_detail node={@node} relationships={@relationships} />
    <% else %>
      <.knowledge_index
        tech_count={@tech_count}
        vuln_count={@vuln_count}
        control_count={@control_count}
        practice_count={@practice_count}
        selected_type={@selected_type}
        search_query={@search_query}
        nodes={@nodes}
      />
    <% end %>
    """
  end

  defp knowledge_index(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      <!-- Header -->
      <div class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
          <div class="flex items-center justify-between">
            <div>
              <h1 class="text-3xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
                Knowledge Base
              </h1>
              <p class="mt-2 text-gray-600 dark:text-gray-400">
                Explore our curated security knowledge graph
              </p>
            </div>
            <.link
              navigate={~p"/"}
              class="inline-flex items-center px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-700 rounded-lg border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
            >
              ← Back to Home
            </.link>
          </div>
        </div>
      </div>

      <!-- Stats Bar -->
      <div class="bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 py-8">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="bg-white/10 backdrop-blur-lg rounded-lg p-4 text-center">
              <div class="text-3xl font-bold text-white">{@tech_count}</div>
              <div class="text-sm text-white/80">Technologies</div>
            </div>
            <div class="bg-white/10 backdrop-blur-lg rounded-lg p-4 text-center">
              <div class="text-3xl font-bold text-white">{@vuln_count}</div>
              <div class="text-sm text-white/80">Vulnerabilities</div>
            </div>
            <div class="bg-white/10 backdrop-blur-lg rounded-lg p-4 text-center">
              <div class="text-3xl font-bold text-white">{@control_count}</div>
              <div class="text-sm text-white/80">Security Controls</div>
            </div>
            <div class="bg-white/10 backdrop-blur-lg rounded-lg p-4 text-center">
              <div class="text-3xl font-bold text-white">{@practice_count}</div>
              <div class="text-sm text-white/80">Best Practices</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <!-- Search and Filter -->
        <div class="mb-8 space-y-4">
          <!-- Search Bar -->
          <div class="relative">
            <form phx-change="search">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Search knowledge base..."
                class="w-full px-4 py-3 pl-12 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <svg class="absolute left-4 top-3.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </form>
          </div>

          <!-- Filter Buttons -->
          <div class="flex flex-wrap gap-2">
            <button
              phx-click="filter_type"
              phx-value-type="all"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all",
                if(@selected_type == "all",
                  do: "bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg",
                  else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:border-blue-500"
                )
              ]}
            >
              All
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="Technology"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all",
                if(@selected_type == "Technology",
                  do: "bg-gradient-to-r from-blue-600 to-cyan-600 text-white shadow-lg",
                  else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:border-blue-500"
                )
              ]}
            >
              Technologies ({@tech_count})
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="Vulnerability"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all",
                if(@selected_type == "Vulnerability",
                  do: "bg-gradient-to-r from-red-600 to-pink-600 text-white shadow-lg",
                  else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:border-red-500"
                )
              ]}
            >
              Vulnerabilities ({@vuln_count})
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="SecurityControl"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all",
                if(@selected_type == "SecurityControl",
                  do: "bg-gradient-to-r from-green-600 to-emerald-600 text-white shadow-lg",
                  else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:border-green-500"
                )
              ]}
            >
              Security Controls ({@control_count})
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="BestPractice"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all",
                if(@selected_type == "BestPractice",
                  do: "bg-gradient-to-r from-purple-600 to-indigo-600 text-white shadow-lg",
                  else: "bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 hover:border-purple-500"
                )
              ]}
            >
              Best Practices ({@practice_count})
            </button>
          </div>
        </div>

        <!-- Results -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <%= for node <- @nodes do %>
            <.link navigate={~p"/knowledge/#{node.id}"} class="group relative block">
              <div class={"absolute -inset-0.5 bg-gradient-to-r opacity-0 group-hover:opacity-100 transition duration-300 rounded-2xl blur #{gradient_for_type(node.type)}"}>
              </div>
              <div class="relative bg-white dark:bg-gray-800 rounded-2xl p-6 border border-gray-200 dark:border-gray-700 cursor-pointer hover:shadow-xl transition-shadow">
                <!-- Type Badge -->
                <div class="mb-4">
                  <span class={"inline-flex items-center px-3 py-1 rounded-full text-xs font-medium #{badge_color_for_type(node.type)}"}>
                    {node.type}
                  </span>
                </div>

                <!-- Name -->
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                  {node.name}
                </h3>

                <!-- Properties -->
                <div class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
                  <%= case node.type do %>
                    <% "Technology" -> %>
                      <%= if node.properties["category"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Category:</span>
                          <span>{node.properties["category"]}</span>
                        </div>
                      <% end %>
                      <%= if node.properties["version"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Version:</span>
                          <span>{node.properties["version"]}</span>
                        </div>
                      <% end %>
                    <% "Vulnerability" -> %>
                      <%= if node.properties["severity"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Severity:</span>
                          <span class={"px-2 py-0.5 rounded #{severity_badge(node.properties["severity"])}"}>{node.properties["severity"]}</span>
                        </div>
                      <% end %>
                      <%= if node.properties["owasp_rank"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">OWASP:</span>
                          <span>{node.properties["owasp_rank"]}</span>
                        </div>
                      <% end %>
                    <% "SecurityControl" -> %>
                      <%= if node.properties["category"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Category:</span>
                          <span>{node.properties["category"]}</span>
                        </div>
                      <% end %>
                      <%= if node.properties["implementation_difficulty"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Difficulty:</span>
                          <span>{node.properties["implementation_difficulty"]}</span>
                        </div>
                      <% end %>
                    <% "BestPractice" -> %>
                      <%= if node.properties["technology"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Technology:</span>
                          <span>{node.properties["technology"]}</span>
                        </div>
                      <% end %>
                      <%= if node.properties["category"] do %>
                        <div class="flex items-center gap-2">
                          <span class="font-medium">Category:</span>
                          <span>{node.properties["category"]}</span>
                        </div>
                      <% end %>
                    <% _ -> %>
                  <% end %>

                  <%= if node.properties["description"] do %>
                    <p class="mt-3 text-gray-700 dark:text-gray-300">
                      {node.properties["description"]}
                    </p>
                  <% end %>
                </div>
              </div>
            </.link>
          <% end %>

          <%= if Enum.empty?(@nodes) do %>
            <div class="col-span-full text-center py-12">
              <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
              </svg>
              <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No results found</h3>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Try adjusting your search or filter.
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp node_detail(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      <!-- Header -->
      <div class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
          <div class="flex items-center gap-4">
            <.link
              navigate={~p"/knowledge"}
              class="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-700 rounded-lg border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
            >
              ← Back to Knowledge Base
            </.link>
          </div>
          <div class="mt-6">
            <span class={"inline-flex items-center px-3 py-1 rounded-full text-sm font-medium #{badge_color_for_type(@node.type)}"}>
              {@node.type}
            </span>
            <h1 class="mt-4 text-4xl font-bold text-gray-900 dark:text-white">
              {@node.name}
            </h1>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Main Content -->
          <div class="lg:col-span-2 space-y-6">
            <!-- Properties Card -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 border border-gray-200 dark:border-gray-700">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Properties</h2>
              <dl class="space-y-3">
                <%= for {key, value} <- @node.properties do %>
                  <%= if value && value != "" do %>
                    <div class="flex flex-col sm:flex-row sm:items-start gap-2">
                      <dt class="font-medium text-gray-700 dark:text-gray-300 sm:w-1/3">
                        {humanize_key(key)}:
                      </dt>
                      <dd class="text-gray-900 dark:text-gray-100 sm:w-2/3">
                        <%= if key == "severity" do %>
                          <span class={"px-2 py-1 rounded-lg text-sm #{severity_badge(value)}"}>{value}</span>
                        <% else %>
                          {value}
                        <% end %>
                      </dd>
                    </div>
                  <% end %>
                <% end %>
              </dl>
            </div>

            <!-- Relationships Card -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 border border-gray-200 dark:border-gray-700">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-4">Relationships</h2>

              <%= if Enum.empty?(@relationships) do %>
                <p class="text-gray-500 dark:text-gray-400">No relationships found.</p>
              <% else %>
                <div class="space-y-6">
                  <%= for {rel_type, rels} <- group_relationships(@relationships) do %>
                    <div>
                      <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 uppercase tracking-wide mb-3">
                        {humanize_relationship_type(rel_type)}
                      </h3>
                      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <%= for rel <- rels do %>
                          <.link
                            navigate={~p"/knowledge/#{rel.node.id}"}
                            class="group relative block p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg border border-gray-200 dark:border-gray-600 hover:border-blue-500 dark:hover:border-blue-400 transition-all hover:shadow-md"
                          >
                            <div class="flex items-start justify-between">
                              <div class="flex-1">
                                <span class={"inline-flex items-center px-2 py-0.5 rounded text-xs font-medium mb-2 #{badge_color_for_type(rel.node.type)}"}>
                                  {rel.node.type}
                                </span>
                                <p class="font-medium text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400">
                                  {rel.node.name}
                                </p>
                                <%= if rel.node.properties["description"] do %>
                                  <p class="mt-1 text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                                    {rel.node.properties["description"]}
                                  </p>
                                <% end %>
                              </div>
                              <svg class="w-5 h-5 text-gray-400 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                              </svg>
                            </div>
                          </.link>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Sidebar -->
          <div class="space-y-6">
            <!-- Quick Stats -->
            <div class="bg-gradient-to-br from-blue-600 to-purple-600 rounded-2xl p-6 text-white">
              <h3 class="text-lg font-semibold mb-4">Connections</h3>
              <div class="space-y-2">
                <div class="flex justify-between items-center">
                  <span class="text-blue-100">Total Relationships</span>
                  <span class="text-2xl font-bold">{length(@relationships)}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span class="text-blue-100">Outgoing</span>
                  <span class="text-xl font-semibold">{count_by_direction(@relationships, "outgoing")}</span>
                </div>
                <div class="flex justify-between items-center">
                  <span class="text-blue-100">Incoming</span>
                  <span class="text-xl font-semibold">{count_by_direction(@relationships, "incoming")}</span>
                </div>
              </div>
            </div>

            <!-- Related Types -->
            <%= if !Enum.empty?(@relationships) do %>
              <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 border border-gray-200 dark:border-gray-700">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Connected Types</h3>
                <div class="space-y-2">
                  <%= for {type, count} <- count_related_types(@relationships) do %>
                    <div class="flex justify-between items-center">
                      <span class={"inline-flex items-center px-2 py-1 rounded text-xs font-medium #{badge_color_for_type(type)}"}>
                        {type}
                      </span>
                      <span class="text-sm font-medium text-gray-600 dark:text-gray-400">{count}</span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp group_relationships(relationships) do
    relationships
    |> Enum.group_by(& &1.type)
  end

  defp count_by_direction(relationships, direction) do
    relationships
    |> Enum.count(&(&1.direction == direction))
  end

  defp count_related_types(relationships) do
    relationships
    |> Enum.map(& &1.node.type)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_type, count} -> -count end)
  end

  defp humanize_key(key) when is_binary(key) do
    key
    |> String.replace("_", " ")
    |> String.capitalize()
  end
  defp humanize_key(key), do: to_string(key)

  defp humanize_relationship_type(rel_type) do
    rel_type
    |> String.replace("_", " ")
    |> String.downcase()
  end

  defp gradient_for_type("Technology"), do: "from-blue-600 to-cyan-600"
  defp gradient_for_type("Vulnerability"), do: "from-red-600 to-pink-600"
  defp gradient_for_type("SecurityControl"), do: "from-green-600 to-emerald-600"
  defp gradient_for_type("BestPractice"), do: "from-purple-600 to-indigo-600"
  defp gradient_for_type(_), do: "from-gray-600 to-gray-400"

  defp badge_color_for_type("Technology"), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
  defp badge_color_for_type("Vulnerability"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp badge_color_for_type("SecurityControl"), do: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
  defp badge_color_for_type("BestPractice"), do: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200"
  defp badge_color_for_type(_), do: "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"

  defp severity_badge("critical"), do: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  defp severity_badge("high"), do: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200"
  defp severity_badge("medium"), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
  defp severity_badge(_), do: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200"
end
