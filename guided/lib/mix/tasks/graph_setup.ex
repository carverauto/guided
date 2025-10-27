defmodule Mix.Tasks.Graph.Setup do
  @moduledoc """
  Sets up the initial graph schema for guided.dev.

  This task creates the foundational node labels and relationship types
  that will be used in the knowledge graph.

  Run with: mix graph.setup
  """

  use Mix.Task
  alias Guided.Graph

  @shortdoc "Sets up the initial graph schema"

  @doc """
  Creates the basic graph schema by defining node labels and relationship types.

  According to the PRD, the graph data model includes:

  Nodes:
  - Concept: High-level concepts in software development
  - Technology: Specific technologies (languages, frameworks, tools)
  - UseCase: Common use cases and scenarios
  - BestPractice: Recommended practices and patterns
  - DeploymentPattern: Deployment strategies and patterns
  - Vulnerability: Known security vulnerabilities
  - SecurityControl: Security controls and mitigations

  Relationships:
  - RECOMMENDED_FOR: Technology -> UseCase
  - HAS_BEST_PRACTICE: Technology -> BestPractice
  - HAS_VULNERABILITY: Technology -> Vulnerability
  - MITIGATED_BY: Vulnerability -> SecurityControl
  - IMPLEMENTS_CONTROL: BestPractice -> SecurityControl
  """
  def run(_args) do
    Mix.Task.run("app.start")

    Mix.shell().info("Setting up guided.dev graph schema...")

    # In AGE, node labels and relationship types are created dynamically
    # when nodes/edges are first created. However, we can verify the graph
    # exists and is ready to use.

    case verify_graph() do
      {:ok, _} ->
        Mix.shell().info("✓ Graph schema verified and ready")
        Mix.shell().info("\nDefined node types:")
        Mix.shell().info("  - Concept")
        Mix.shell().info("  - Technology")
        Mix.shell().info("  - UseCase")
        Mix.shell().info("  - BestPractice")
        Mix.shell().info("  - DeploymentPattern")
        Mix.shell().info("  - Vulnerability")
        Mix.shell().info("  - SecurityControl")
        Mix.shell().info("\nDefined relationship types:")
        Mix.shell().info("  - RECOMMENDED_FOR")
        Mix.shell().info("  - HAS_BEST_PRACTICE")
        Mix.shell().info("  - HAS_VULNERABILITY")
        Mix.shell().info("  - MITIGATED_BY")
        Mix.shell().info("  - IMPLEMENTS_CONTROL")

      {:error, error} ->
        Mix.shell().error("Error verifying graph: #{inspect(error)}")
        Mix.shell().error("Make sure PostgreSQL with AGE is running and configured correctly")
    end
  end

  defp verify_graph do
    # Simple query to verify the graph is accessible
    Graph.query("MATCH (n) RETURN count(n) as node_count")
  end
end
