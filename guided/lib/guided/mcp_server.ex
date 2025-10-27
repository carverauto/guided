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
    {:reply, result, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  @impl true
  def handle_tool_call("secure_coding_pattern", params, frame) do
    result = secure_coding_pattern(params)
    {:reply, result, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  @impl true
  def handle_tool_call("deployment_guidance", params, frame) do
    result = deployment_guidance(params)
    {:reply, result, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  # Tech Stack Recommendation Implementation
  defp tech_stack_recommendation(%{intent: intent} = params) do
    context = Map.get(params, :context, %{})

    # Determine use case based on intent
    use_case = infer_use_case(intent, context)

    # Query for recommended technologies for this use case
    cypher_query = """
    MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: $use_case})
    OPTIONAL MATCH (t)-[:HAS_VULNERABILITY]->(v:Vulnerability)
    OPTIONAL MATCH (v)-[:MITIGATED_BY]->(sc:SecurityControl)
    RETURN t.name as technology,
           t.category as category,
           t.description as description,
           t.security_rating as security_rating,
           collect(DISTINCT {
             name: v.name,
             severity: v.severity,
             description: v.description,
             mitigations: collect(DISTINCT sc.name)
           }) as vulnerabilities
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
    cypher_query = """
    MATCH (t:Technology {name: $technology})-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
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
    # This is a simplified query - in production, we'd match on more complex criteria
    cypher_query = """
    MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)-[:RECOMMENDED_DEPLOYMENT]->(dp:DeploymentPattern)
    WHERE t.name IN $technologies
    RETURN DISTINCT dp.name as pattern_name,
           dp.platform as platform,
           dp.cost as cost,
           dp.complexity as complexity,
           dp.description as description,
           dp.https_support as https_support,
           collect(DISTINCT uc.name) as use_cases
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
  defp parse_tech_recommendations(results) do
    Enum.map(results, fn tech ->
      # Extract technology data
      technology = Map.get(tech, "technology", "")
      category = Map.get(tech, "category", "")
      description = Map.get(tech, "description", "")
      security_rating = Map.get(tech, "security_rating", "")

      # Parse vulnerabilities (they come as a list of maps)
      vulnerabilities = Map.get(tech, "vulnerabilities", [])
      |> Enum.filter(fn v -> v["name"] != nil end)
      |> Enum.map(fn v ->
        %{
          name: v["name"],
          severity: v["severity"],
          description: v["description"],
          mitigations: v["mitigations"] || []
        }
      end)

      %{
        technology: technology,
        category: category,
        description: description,
        security_rating: security_rating,
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
  defp parse_deployment_patterns(results, _requirements) do
    results
    |> Enum.map(fn pattern ->
      %{
        name: Map.get(pattern, "pattern_name", ""),
        platform: Map.get(pattern, "platform", ""),
        cost: Map.get(pattern, "cost", ""),
        complexity: Map.get(pattern, "complexity", ""),
        description: Map.get(pattern, "description", ""),
        https_support: Map.get(pattern, "https_support", false),
        use_cases: Map.get(pattern, "use_cases", [])
      }
    end)
    |> Enum.uniq_by(& &1.name)
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
