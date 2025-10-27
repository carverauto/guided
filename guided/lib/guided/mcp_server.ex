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
  alias Hermes.Server.Response

  @impl true
  def init(_client_info, frame) do
    {:ok,
     frame
     |> assign(query_count: 0)
     |> register_tool("tech_stack_recommendation",
       input_schema: %{
         intent:
           {:required, :string,
            max: 200, description: "What you want to build (e.g., 'build a web app')"},
         context:
           {:optional, {:map, :any},
            description: "Additional context like topic, user scale, complexity"}
       },
       description:
         "Get opinionated advice on the best and most secure tech stack for a given use case"
     )
     |> register_tool("secure_coding_pattern",
       input_schema: %{
         technology:
           {:required, :string,
            max: 100, description: "Technology name (e.g., 'Streamlit', 'SQLite')"},
         task:
           {:optional, :string,
            max: 200,
            description: "Specific task or concern (e.g., 'database query', 'authentication')"}
       },
       description:
         "Retrieve secure code snippets and patterns for a specific technology and task"
     )
     |> register_tool("deployment_guidance",
       input_schema: %{
         stack:
           {:required, {:list, :string},
            description: "List of technologies in your stack (e.g., ['Streamlit', 'SQLite'])"},
         requirements:
           {:optional, {:map, :any},
            description: "Requirements like user_load, custom_domain, budget"}
       },
       description: "Get recommendations for secure deployment patterns based on your tech stack"
     )}
  end

  @impl true
  def handle_tool_call("tech_stack_recommendation", params, frame) do
    result = tech_stack_recommendation(params)

    response =
      Response.tool()
      |> Response.structured(result)

    {:reply, response, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  @impl true
  def handle_tool_call("secure_coding_pattern", params, frame) do
    result = secure_coding_pattern(params)

    response =
      Response.tool()
      |> Response.structured(result)

    {:reply, response, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  @impl true
  def handle_tool_call("deployment_guidance", params, frame) do
    result = deployment_guidance(params)

    response =
      Response.tool()
      |> Response.structured(result)

    {:reply, response, assign(frame, query_count: frame.assigns.query_count + 1)}
  end

  # Tech Stack Recommendation Implementation
  defp tech_stack_recommendation(params) do
    params = normalize_params(params)

    with {:ok, intent} <- fetch_required_string(params, "intent"),
         {:ok, context} <- normalize_context(Map.get(params, "context")) do
      intent = String.trim(intent)

      if intent == "" do
        %{
          status: "error",
          message: "Intent must not be blank."
        }
      else
        # Determine use case based on intent
        use_case = infer_use_case(intent, context)

        # Query for recommended technologies for this use case
        # Note: We return flat results and group them in Elixir to avoid nested collect()
        # Note: AGE doesn't support parameterized queries, so we interpolate directly (with escaping)
        # Note: Return a single map object to match AGE's result type expectations
        escaped_use_case = String.replace(use_case, "'", "\\'")

        cypher_query = """
        MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: '#{escaped_use_case}'})
        OPTIONAL MATCH (t)-[:HAS_VULNERABILITY]->(v:Vulnerability)
        OPTIONAL MATCH (v)-[:MITIGATED_BY]->(sc:SecurityControl)
        RETURN {
          technology: t.name,
          category: t.category,
          description: t.description,
          security_rating: t.security_rating,
          vuln_name: v.name,
          vuln_severity: v.severity,
          vuln_description: v.description,
          mitigation_name: sc.name
        }
        """

        case Graph.query(cypher_query, []) do
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
    else
      {:error, message} ->
        %{
          status: "error",
          message: message
        }
    end
  end

  # Secure Coding Pattern Implementation
  defp secure_coding_pattern(params) do
    params = normalize_params(params)

    with {:ok, technology} <- fetch_required_string(params, "technology"),
         {:ok, task} <- normalize_optional_string(Map.get(params, "task"), "task") do
      technology = String.trim(technology)
      task = String.trim(task)

      if technology == "" do
        %{
          status: "error",
          message: "Technology must not be blank."
        }
      else
        # Query for best practices related to this technology
        # Note: AGE doesn't support parameterized queries, so we interpolate directly (with escaping)
        # Note: Return a single map object to match AGE's result type expectations
        escaped_technology = String.replace(technology, "'", "\\'")

        cypher_query = """
        MATCH (t:Technology {name: '#{escaped_technology}'})-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
        OPTIONAL MATCH (bp)-[:IMPLEMENTS_CONTROL]->(sc:SecurityControl)
        RETURN {
          practice_name: bp.name,
          category: bp.category,
          description: bp.description,
          code_example: bp.code_example,
          security_control: sc.name
        }
        """

        case Graph.query(cypher_query, []) do
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
    else
      {:error, message} ->
        %{
          status: "error",
          message: message
        }
    end
  end

  # Deployment Guidance Implementation
  defp deployment_guidance(params) do
    params = normalize_params(params)

    with {:ok, stack} <- normalize_stack(Map.get(params, "stack")),
         {:ok, requirements} <- normalize_requirements(Map.get(params, "requirements")) do
      # Query for deployment patterns recommended for the use cases these technologies support
      # Note: AGE doesn't support parameterized queries, build list inline
      # Note: Return a single map object to match AGE's result type expectations
      escaped_stack =
        Enum.map(stack, fn tech -> "'#{String.replace(tech, "'", "\\'")}'" end) |> Enum.join(", ")

      cypher_query = """
      MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)-[:RECOMMENDED_DEPLOYMENT]->(dp:DeploymentPattern)
      WHERE t.name IN [#{escaped_stack}]
      RETURN {
        pattern_name: dp.name,
        platform: dp.platform,
        cost: dp.cost,
        complexity: dp.complexity,
        description: dp.description,
        https_support: dp.https_support,
        use_case: uc.name
      }
      """

      case Graph.query(cypher_query, []) do
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
    else
      {:error, message} ->
        %{
          status: "error",
          message: message
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
    normalized_task = normalize_for_match(task)

    if normalized_task == "" do
      practices
    else
      tokens =
        normalized_task
        |> String.split(" ")
        |> Enum.filter(&(String.length(&1) >= 3))

      Enum.filter(practices, fn practice ->
        fields = [practice.name, practice.category, practice.description]

        direct_match? =
          Enum.any?(fields, fn field ->
            field
            |> to_string()
            |> String.downcase()
            |> String.contains?(task_lower)
          end)

        token_match? =
          Enum.any?(
            Enum.map(fields, &normalize_for_match/1),
            fn field ->
              Enum.any?(tokens, fn token -> token != "" and String.contains?(field, token) end)
            end
          )

        direct_match? or token_match?
      end)
    end
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
    scored_patterns =
      Enum.map(patterns, fn pattern ->
        score = 0

        score =
          if Map.get(requirements, "budget") == "free" and pattern.cost =~ "free",
            do: score + 10,
            else: score

        score =
          if Map.get(requirements, "complexity") == "low" and pattern.complexity == "low",
            do: score + 5,
            else: score

        score =
          if Map.get(requirements, "https") == true and pattern.https_support,
            do: score + 5,
            else: score

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

  defp normalize_params(params) when is_map(params) do
    Map.new(params, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} when is_binary(key) -> {key, value}
      {key, value} -> {to_string(key), value}
    end)
  end

  defp normalize_params(_), do: %{}

  defp fetch_required_string(params, key) do
    case Map.get(params, key) do
      nil -> {:error, "Missing required parameter '#{key}'."}
      value -> normalize_string(value, key)
    end
  end

  defp normalize_string(value, _key) when is_binary(value), do: {:ok, value}
  defp normalize_string(value, _key) when is_atom(value), do: {:ok, Atom.to_string(value)}
  defp normalize_string(value, _key) when is_number(value), do: {:ok, to_string(value)}
  defp normalize_string(_value, key), do: {:error, "Parameter '#{key}' must be a string."}

  defp normalize_optional_string(nil, _key), do: {:ok, ""}

  defp normalize_optional_string(value, _key) when is_binary(value),
    do: {:ok, value}

  defp normalize_optional_string(value, _key) when is_atom(value),
    do: {:ok, Atom.to_string(value)}

  defp normalize_optional_string(value, _key) when is_number(value),
    do: {:ok, to_string(value)}

  defp normalize_optional_string(_value, key),
    do: {:error, "Parameter '#{key}' must be a string if provided."}

  defp normalize_context(nil), do: {:ok, %{}}

  defp normalize_context(%{} = map) do
    {:ok, stringify_keys(map)}
  end

  defp normalize_context(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, %{} = map} -> {:ok, stringify_keys(map)}
      {:ok, _} -> {:error, "Context must be a JSON object."}
      {:error, _} -> {:error, "Context must be a JSON object."}
    end
  end

  defp normalize_context(_value), do: {:error, "Context must be a map or JSON object."}

  defp normalize_stack(stack) when is_list(stack) do
    {:ok, Enum.map(stack, &to_string/1)}
  end

  defp normalize_stack(stack) when is_binary(stack) do
    trimmed = String.trim(stack)

    case Jason.decode(trimmed) do
      {:ok, list} when is_list(list) ->
        {:ok, Enum.map(list, &to_string/1)}

      {:error, _} ->
        parts =
          trimmed
          |> String.split(",", trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.trim(&1, "\""))

        if Enum.empty?(parts) do
          {:error, "Stack must contain at least one technology name."}
        else
          {:ok, parts}
        end
    end
  end

  defp normalize_stack(_stack) do
    {:error, "Stack parameter must be a list of technology names."}
  end

  defp normalize_requirements(nil), do: {:ok, %{}}
  defp normalize_requirements(%{} = map), do: {:ok, stringify_keys(map)}

  defp normalize_requirements(req) when is_binary(req) do
    case Jason.decode(req) do
      {:ok, %{} = map} -> {:ok, stringify_keys(map)}
      {:ok, _} -> {:error, "Requirements must be an object with key/value pairs."}
      {:error, _} -> {:error, "Requirements must be a JSON object or map."}
    end
  end

  defp normalize_requirements(_), do: {:error, "Requirements must be a JSON object or map."}

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp normalize_for_match(nil), do: ""

  defp normalize_for_match(text) do
    text
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
