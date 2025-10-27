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
     |> load_stats()
     |> load_nodes()}
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

  @impl true
  def render(assigns) do
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
            <div class="group relative">
              <div class={"absolute -inset-0.5 bg-gradient-to-r opacity-0 group-hover:opacity-100 transition duration-300 rounded-2xl blur #{gradient_for_type(node.type)}"}>
              </div>
              <div class="relative bg-white dark:bg-gray-800 rounded-2xl p-6 border border-gray-200 dark:border-gray-700">
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
            </div>
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
