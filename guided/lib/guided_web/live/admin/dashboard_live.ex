defmodule GuidedWeb.Admin.DashboardLive do
  use GuidedWeb, :live_view

  alias Guided.Graph

  @impl true
  def mount(_params, _session, socket) do
    # Get total node count
    {:ok, [node_count]} = Graph.query("MATCH (n) RETURN count(n)")

    # Get edge count - use a simpler pattern that AGE handles better
    edge_count = case Graph.query("MATCH (a)-[r]->(b) RETURN count(r)") do
      {:ok, [count]} -> count
      _ -> 0
    end

    # Get counts by node type
    tech_count = case Graph.query("MATCH (n:Technology) RETURN count(n)") do
      {:ok, [count]} -> count
      _ -> 0
    end

    vuln_count = case Graph.query("MATCH (n:Vulnerability) RETURN count(n)") do
      {:ok, [count]} -> count
      _ -> 0
    end

    control_count = case Graph.query("MATCH (n:SecurityControl) RETURN count(n)") do
      {:ok, [count]} -> count
      _ -> 0
    end

    practice_count = case Graph.query("MATCH (n:BestPractice) RETURN count(n)") do
      {:ok, [count]} -> count
      _ -> 0
    end

    socket =
      socket
      |> assign(:page_title, "Admin Dashboard")
      |> assign(:node_count, node_count)
      |> assign(:edge_count, edge_count)
      |> assign(:tech_count, tech_count)
      |> assign(:vuln_count, vuln_count)
      |> assign(:control_count, control_count)
      |> assign(:practice_count, practice_count)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Knowledge Graph Dashboard</h1>
        <p class="mt-2 text-sm text-gray-700">
          Manage the guided.dev knowledge base
        </p>
      </div>

      <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Nodes</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
            {@node_count}
          </dd>
        </div>

        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6">
          <dt class="truncate text-sm font-medium text-gray-500">Total Relationships</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
            {@edge_count}
          </dd>
        </div>

        <.link
          navigate={~p"/admin/technologies"}
          class="overflow-hidden rounded-lg bg-blue-50 px-4 py-5 shadow sm:p-6 hover:bg-blue-100 transition-colors"
        >
          <dt class="truncate text-sm font-medium text-blue-700">Technologies</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-blue-900">
            {@tech_count}
          </dd>
        </.link>

        <.link
          navigate={~p"/admin/vulnerabilities"}
          class="overflow-hidden rounded-lg bg-red-50 px-4 py-5 shadow sm:p-6 hover:bg-red-100 transition-colors"
        >
          <dt class="truncate text-sm font-medium text-red-700">Vulnerabilities</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-red-900">
            {@vuln_count}
          </dd>
        </.link>

        <.link
          navigate={~p"/admin/security_controls"}
          class="overflow-hidden rounded-lg bg-green-50 px-4 py-5 shadow sm:p-6 hover:bg-green-100 transition-colors"
        >
          <dt class="truncate text-sm font-medium text-green-700">Security Controls</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-green-900">
            {@control_count}
          </dd>
        </.link>

        <.link
          navigate={~p"/admin/best_practices"}
          class="overflow-hidden rounded-lg bg-purple-50 px-4 py-5 shadow sm:p-6 hover:bg-purple-100 transition-colors"
        >
          <dt class="truncate text-sm font-medium text-purple-700">Best Practices</dt>
          <dd class="mt-1 text-3xl font-semibold tracking-tight text-purple-900">
            {@practice_count}
          </dd>
        </.link>
      </div>

      <div class="mt-8">
        <h2 class="text-lg font-medium text-gray-900">Quick Actions</h2>
        <div class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <.link
            navigate={~p"/admin/technologies/new"}
            class="inline-flex items-center justify-center rounded-md bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            Add Technology
          </.link>

          <.link
            navigate={~p"/admin/vulnerabilities/new"}
            class="inline-flex items-center justify-center rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2"
          >
            Add Vulnerability
          </.link>

          <.link
            navigate={~p"/admin/best_practices/new"}
            class="inline-flex items-center justify-center rounded-md bg-purple-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2"
          >
            Add Best Practice
          </.link>

          <.link
            navigate={~p"/admin/relationships"}
            class="inline-flex items-center justify-center rounded-md bg-gray-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
          >
            Manage Relationships
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
