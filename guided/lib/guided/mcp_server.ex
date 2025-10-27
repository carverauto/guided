defmodule Guided.MCPServer do
  @moduledoc """
  Model Context Protocol (MCP) server for guided.dev.

  Exposes three core capabilities to AI agents:
  - `tech_stack_recommendation`: Get opinionated tech stack advice for a use case
  - `secure_coding_pattern`: Retrieve secure code patterns for specific technologies
  - `deployment_guidance`: Get deployment recommendations for a tech stack

  This server implements the AGENTS.md protocol specification.
  """

  use Hermes.Server,
    name: "guided.dev MCP Server",
    version: "1.0.0",
    capabilities: [:tools]

  alias Guided.Graph

  @impl true
  def init(_client_info, frame) do
    {:ok,
     frame
     |> assign(query_count: 0)
     |> register_tool("tech_stack_recommendation",
       input_schema: %{
         intent: {:required, :string, max: 200, description: "What you want to build (e.g., 'build a web app')"},
         context: {:optional, :map, description: "Additional context like topic, user scale, complexity"}
       },
       description: "Get opinionated advice on the best and most secure tech stack for a given use case"
     )
     |> register_tool("secure_coding_pattern",
       input_schema: %{
         technology: {:required, :string, max: 100, description: "Technology name (e.g., 'Streamlit', 'SQLite')"},
         task: {:optional, :string, max: 200, description: "Specific task or concern (e.g., 'database query', 'authentication')"}
       },
       description: "Retrieve secure code snippets and patterns for a specific technology and task"
     )
     |> register_tool("deployment_guidance",
       input_schema: %{
         stack: {:required, :list, description: "List of technologies in your stack (e.g., ['Streamlit', 'SQLite'])"},
         requirements: {:optional, :map, description: "Requirements like user_load, custom_domain, budget"}
       },
       description: "Get recommendations for secure deployment patterns based on your tech stack"
     )}
  end

  @impl true
  def handle_tool_call("tech_stack_recommendation", params, frame) do
    result = tech_stack_recommendation(params)
    # Hermes expects a text response directly, it handles the MCP wrapping
    text_result = Jason.encode!(result, pretty: true)
    {:reply, text_result, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  @impl true
  def handle_tool_call("secure_coding_pattern", params, frame) do
    result = secure_coding_pattern(params)
    # Hermes expects a text response directly, it handles the MCP wrapping
    text_result = Jason.encode!(result, pretty: true)
    {:reply, text_result, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  @impl true
  def handle_tool_call("deployment_guidance", params, frame) do
    result = deployment_guidance(params)
    # Hermes expects a text response directly, it handles the MCP wrapping
    text_result = Jason.encode!(result, pretty: true)
    {:reply, text_result, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  # Tech Stack Recommendation Implementation
  defp tech_stack_recommendation(%{intent: intent} = params) do
    context = Map.get(params, :context, %{})

    # Determine use case based on intent
    use_case = infer_use_case(intent, context)

    # Query for recommended technologies for this use case
    # Note: We return flat results and group them in Elixir to avoid nested collect()
    # Note: AGE doesn't support parameters in property matchers, use WHERE clause
    cypher_query = """
    MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)
    WHERE uc.name = $0
    OPTIONAL MATCH (t)-[:HAS_VULNERABILITY]->(v:Vulnerability)
    OPTIONAL MATCH (v)-[:MITIGATED_BY]->(sc:SecurityControl)
    RETURN t.name as technology,
           t.category as category,
           t.description as description,
           t.security_rating as security_rating,
           v.name as vuln_name,
           v.severity as vuln_severity,
           v.description as vuln_description,
           sc.name as mitigation_name
    """

    case Graph.query(cypher_query, [use_case]) do
      {:ok, results} ->
        # Parse and format the response
        technologies = parse_tech_recommendations(results)

        %{
          status: "success",
          use_case: use_case,
          intent: intent,
          recommendations: technologies,
          guidance: generate_guidance_text(use_case, technologies)
        }

      {:error, error} ->
        %{
          status: "error",
          message: "Failed to query knowledge graph: #{inspect(error)}"
        }
    end
  end

  # Secure Coding Pattern Implementation
  defp secure_coding_pattern(%{technology: technology} = params) do
    task = Map.get(params, :task, "")

    # Query for best practices related to this technology
    # Note: AGE doesn't support parameters in property matchers, use WHERE clause
    cypher_query = """
    MATCH (t:Technology)-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
    WHERE t.name = $0
    OPTIONAL MATCH (bp)-[:IMPLEMENTS_CONTROL]->(sc:SecurityControl)
    RETURN bp.name as practice_name,
           bp.category as category,
           bp.description as description,
           bp.code_example as code_example,
           sc.name as security_control
    """

    case Graph.query(cypher_query, [technology]) do
      {:ok, results} ->
        # Filter by task if provided
        practices = parse_best_practices(results, task)

        %{
          status: "success",
          technology: technology,
          task: task,
          patterns: practices,
          count: length(practices)
        }

      {:error, error} ->
        %{
          status: "error",
          message: "Failed to query knowledge graph: #{inspect(error)}"
        }
    end
  end

  # Deployment Guidance Implementation
  defp deployment_guidance(%{stack: stack} = params) do
    requirements = Map.get(params, :requirements, %{})

    # Query for deployment patterns recommended for the use cases these technologies support
    # Note: Use $0 for positional parameter, return flat results and group in Elixir
    cypher_query = """
    MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)-[:RECOMMENDED_DEPLOYMENT]->(dp:DeploymentPattern)
    WHERE t.name IN $0
    RETURN dp.name as pattern_name,
           dp.platform as platform,
           dp.cost as cost,
           dp.complexity as complexity,
           dp.description as description,
           dp.https_support as https_support,
           uc.name as use_case
    """

    case Graph.query(cypher_query, [stack]) do
      {:ok, results} ->
        patterns = parse_deployment_patterns(results, requirements)

        %{
          status: "success",
          stack: stack,
          requirements: requirements,
          deployment_patterns: patterns,
          recommendation: select_best_deployment(patterns, requirements)
        }

      {:error, error} ->
        %{
          status: "error",
          message: "Failed to query knowledge graph: #{inspect(error)}"
        }
    end
  end

  # Helper: Infer use case from intent string
  defp infer_use_case(intent, context) do
    intent_lower = String.downcase(intent)

    cond do
      String.contains?(intent_lower, ["dashboard", "visualization", "chart", "data"]) ->
        "data_dashboard"

      String.contains?(intent_lower, ["api", "rest", "service", "backend"]) ->
        "api_service"

      # Check context for scale hints
      Map.get(context, "users") in ["small", "personal", "small_team"] or
      String.contains?(intent_lower, ["web app", "webapp", "small", "personal"]) ->
        "web_app_small_team"

      # Default to small web app
      true ->
        "web_app_small_team"
    end
  end

  # Helper: Parse technology recommendations from graph results
  # Results come as flat rows, we need to group by technology, then by vulnerability
  defp parse_tech_recommendations(results) do
    results
    |> Enum.group_by(fn row -> Map.get(row, "technology") end)
    |> Enum.map(fn {tech_name, rows} ->
      # Get technology info from first row
      first_row = List.first(rows)

      # Group vulnerabilities and their mitigations
      vulnerabilities =
        rows
        |> Enum.group_by(fn row -> Map.get(row, "vuln_name") end)
        |> Enum.filter(fn {vuln_name, _rows} -> vuln_name != nil end)
        |> Enum.map(fn {vuln_name, vuln_rows} ->
          first_vuln_row = List.first(vuln_rows)

          mitigations =
            vuln_rows
            |> Enum.map(fn row -> Map.get(row, "mitigation_name") end)
            |> Enum.filter(fn m -> m != nil end)
            |> Enum.uniq()

          %{
            name: vuln_name,
            severity: Map.get(first_vuln_row, "vuln_severity"),
            description: Map.get(first_vuln_row, "vuln_description"),
            mitigations: mitigations
          }
        end)

      %{
        technology: tech_name,
        category: Map.get(first_row, "category", ""),
        description: Map.get(first_row, "description", ""),
        security_rating: Map.get(first_row, "security_rating", ""),
        security_advisories: vulnerabilities
      }
    end)
  end

  # Helper: Parse best practices from graph results
  defp parse_best_practices(results, task_filter) do
    results
    |> Enum.map(fn practice ->
      %{
        name: Map.get(practice, "practice_name", ""),
        category: Map.get(practice, "category", ""),
        description: Map.get(practice, "description", ""),
        code_example: Map.get(practice, "code_example", ""),
        security_control: Map.get(practice, "security_control", "")
      }
    end)
    |> filter_by_task(task_filter)
  end

  # Helper: Filter practices by task keyword
  defp filter_by_task(practices, ""), do: practices
  defp filter_by_task(practices, task) do
    task_lower = String.downcase(task)

    Enum.filter(practices, fn practice ->
      name_lower = String.downcase(practice.name)
      category_lower = String.downcase(practice.category)
      desc_lower = String.downcase(practice.description)

      String.contains?(name_lower, task_lower) or
      String.contains?(category_lower, task_lower) or
      String.contains?(desc_lower, task_lower)
    end)
  end

  # Helper: Parse deployment patterns from graph results
  # Results come as flat rows, we need to group by pattern and collect use cases
  defp parse_deployment_patterns(results, _requirements) do
    results
    |> Enum.group_by(fn row -> Map.get(row, "pattern_name") end)
    |> Enum.map(fn {pattern_name, rows} ->
      first_row = List.first(rows)

      # Collect unique use cases for this pattern
      use_cases =
        rows
        |> Enum.map(fn row -> Map.get(row, "use_case") end)
        |> Enum.filter(fn uc -> uc != nil end)
        |> Enum.uniq()

      %{
        name: pattern_name,
        platform: Map.get(first_row, "platform", ""),
        cost: Map.get(first_row, "cost", ""),
        complexity: Map.get(first_row, "complexity", ""),
        description: Map.get(first_row, "description", ""),
        https_support: Map.get(first_row, "https_support", false),
        use_cases: use_cases
      }
    end)
  end

  # Helper: Select best deployment based on requirements
  defp select_best_deployment([], _requirements), do: nil
  defp select_best_deployment(patterns, requirements) do
    # Simple scoring system - in production this would be more sophisticated
    scored_patterns = Enum.map(patterns, fn pattern ->
      score = 0
      score = if Map.get(requirements, "budget") == "free" and pattern.cost =~ "free", do: score + 10, else: score
      score = if Map.get(requirements, "complexity") == "low" and pattern.complexity == "low", do: score + 5, else: score
      score = if Map.get(requirements, "https") == true and pattern.https_support, do: score + 5, else: score

      {pattern, score}
    end)

    {best_pattern, _score} = Enum.max_by(scored_patterns, fn {_pattern, score} -> score end)
    best_pattern
  end

  # Helper: Generate human-readable guidance text
  defp generate_guidance_text(use_case, technologies) do
    tech_names = Enum.map(technologies, & &1.technology) |> Enum.join(", ")

    case use_case do
      "data_dashboard" ->
        "For building a data dashboard, we recommend #{tech_names}. " <>
        "This stack is well-suited for interactive data visualization with minimal setup. " <>
        "Pay special attention to the security advisories listed for each technology."

      "api_service" ->
        "For building an API service, we recommend #{tech_names}. " <>
        "This stack provides modern, high-performance API development capabilities. " <>
        "Review the security advisories to ensure proper input validation and authentication."

      "web_app_small_team" ->
        "For a web application serving a small team, we recommend #{tech_names}. " <>
        "This stack balances simplicity with capability, perfect for rapid development. " <>
        "Follow the security best practices to protect against common vulnerabilities."

      _ ->
        "We recommend #{tech_names} for your use case. " <>
        "Review the security advisories and follow best practices for secure development."
    end
  end
end
