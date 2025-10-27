defmodule Guided.MCPServerTest do
  use Guided.DataCase, async: false

  alias Guided.Graph
  alias Hermes.Server.Frame

  # Ensure the graph is seeded before each test
  setup do
    # Clear and seed the graph for each test
    {:ok, _} = Graph.query("MATCH (n) DETACH DELETE n")

    # Seed minimal test data
    seed_test_data()

    :ok
  end

  defp seed_test_data do
    # Create Technologies
    {:ok, _} =
      Graph.create_node("Technology", %{
        name: "Streamlit",
        category: "framework",
        description: "Python framework for data apps",
        security_rating: "good"
      })

    {:ok, _} =
      Graph.create_node("Technology", %{
        name: "SQLite",
        category: "database",
        description: "Lightweight SQL database",
        security_rating: "good"
      })

    {:ok, _} =
      Graph.create_node("Technology", %{
        name: "FastAPI",
        category: "framework",
        description: "Modern Python web framework",
        security_rating: "excellent"
      })

    # Create Use Cases
    {:ok, _} =
      Graph.create_node("UseCase", %{
        name: "data_dashboard",
        description: "Interactive data dashboard",
        user_scale: "1-1000"
      })

    {:ok, _} =
      Graph.create_node("UseCase", %{
        name: "web_app_small_team",
        description: "Web app for small team",
        user_scale: "1-100"
      })

    {:ok, _} =
      Graph.create_node("UseCase", %{
        name: "api_service",
        description: "RESTful API service",
        user_scale: "variable"
      })

    # Create Vulnerabilities
    {:ok, _} =
      Graph.create_node("Vulnerability", %{
        name: "SQL Injection",
        severity: "critical",
        description: "Malicious SQL injection",
        owasp_rank: "A03:2021"
      })

    {:ok, _} =
      Graph.create_node("Vulnerability", %{
        name: "Cross-Site Scripting (XSS)",
        severity: "high",
        description: "Script injection attacks",
        owasp_rank: "A03:2021"
      })

    # Create Security Controls
    {:ok, _} =
      Graph.create_node("SecurityControl", %{
        name: "Parameterized Queries",
        category: "input_validation",
        description: "Use prepared statements",
        implementation_difficulty: "low"
      })

    {:ok, _} =
      Graph.create_node("SecurityControl", %{
        name: "Input Sanitization",
        category: "input_validation",
        description: "Validate all user inputs",
        implementation_difficulty: "medium"
      })

    {:ok, _} =
      Graph.create_node("SecurityControl", %{
        name: "Output Encoding",
        category: "output_handling",
        description: "Encode output to prevent XSS",
        implementation_difficulty: "low"
      })

    # Create Best Practices
    {:ok, _} =
      Graph.create_node("BestPractice", %{
        name: "Use SQLAlchemy with Parameterized Queries",
        technology: "SQLite",
        category: "database_security",
        description: "Always use parameterized queries",
        code_example: "session.query(User).filter(User.name == user_input)"
      })

    {:ok, _} =
      Graph.create_node("BestPractice", %{
        name: "Streamlit Secret Management",
        technology: "Streamlit",
        category: "configuration",
        description: "Use st.secrets for sensitive config",
        code_example: "db_password = st.secrets['database']['password']"
      })

    {:ok, _} =
      Graph.create_node("BestPractice", %{
        name: "Validate User Inputs in Forms",
        technology: "Streamlit",
        category: "input_validation",
        description: "Always validate user inputs from forms",
        code_example: "if user_input and len(user_input) < 100: ..."
      })

    # Create Deployment Patterns
    {:ok, _} =
      Graph.create_node("DeploymentPattern", %{
        name: "Streamlit Cloud",
        platform: "streamlit_cloud",
        cost: "free_tier_available",
        complexity: "low",
        description: "Official Streamlit hosting",
        https_support: true
      })

    {:ok, _} =
      Graph.create_node("DeploymentPattern", %{
        name: "Fly.io Deployment",
        platform: "fly_io",
        cost: "free_tier_available",
        complexity: "low",
        description: "Deploy to Fly.io",
        https_support: true
      })

    # Create Relationships
    create_rel("Technology", %{name: "Streamlit"}, "RECOMMENDED_FOR", "UseCase", %{
      name: "data_dashboard"
    })

    create_rel("Technology", %{name: "Streamlit"}, "RECOMMENDED_FOR", "UseCase", %{
      name: "web_app_small_team"
    })

    create_rel("Technology", %{name: "FastAPI"}, "RECOMMENDED_FOR", "UseCase", %{
      name: "api_service"
    })

    create_rel("Technology", %{name: "SQLite"}, "RECOMMENDED_FOR", "UseCase", %{
      name: "web_app_small_team"
    })

    create_rel("Technology", %{name: "SQLite"}, "HAS_VULNERABILITY", "Vulnerability", %{
      name: "SQL Injection"
    })

    create_rel("Technology", %{name: "Streamlit"}, "HAS_VULNERABILITY", "Vulnerability", %{
      name: "Cross-Site Scripting (XSS)"
    })

    create_rel("Vulnerability", %{name: "SQL Injection"}, "MITIGATED_BY", "SecurityControl", %{
      name: "Parameterized Queries"
    })

    create_rel("Vulnerability", %{name: "SQL Injection"}, "MITIGATED_BY", "SecurityControl", %{
      name: "Input Sanitization"
    })

    create_rel(
      "Vulnerability",
      %{name: "Cross-Site Scripting (XSS)"},
      "MITIGATED_BY",
      "SecurityControl",
      %{name: "Output Encoding"}
    )

    create_rel("Technology", %{name: "Streamlit"}, "HAS_BEST_PRACTICE", "BestPractice", %{
      name: "Streamlit Secret Management"
    })

    create_rel("Technology", %{name: "Streamlit"}, "HAS_BEST_PRACTICE", "BestPractice", %{
      name: "Validate User Inputs in Forms"
    })

    create_rel("Technology", %{name: "SQLite"}, "HAS_BEST_PRACTICE", "BestPractice", %{
      name: "Use SQLAlchemy with Parameterized Queries"
    })

    create_rel(
      "BestPractice",
      %{name: "Use SQLAlchemy with Parameterized Queries"},
      "IMPLEMENTS_CONTROL",
      "SecurityControl",
      %{name: "Parameterized Queries"}
    )

    create_rel(
      "BestPractice",
      %{name: "Validate User Inputs in Forms"},
      "IMPLEMENTS_CONTROL",
      "SecurityControl",
      %{name: "Input Sanitization"}
    )

    create_rel(
      "UseCase",
      %{name: "data_dashboard"},
      "RECOMMENDED_DEPLOYMENT",
      "DeploymentPattern",
      %{name: "Streamlit Cloud"}
    )

    create_rel(
      "UseCase",
      %{name: "web_app_small_team"},
      "RECOMMENDED_DEPLOYMENT",
      "DeploymentPattern",
      %{name: "Streamlit Cloud"}
    )

    create_rel(
      "UseCase",
      %{name: "web_app_small_team"},
      "RECOMMENDED_DEPLOYMENT",
      "DeploymentPattern",
      %{name: "Fly.io Deployment"}
    )

    :ok
  end

  defp create_rel(from_label, from_props, rel_type, to_label, to_props) do
    Graph.create_relationship(from_label, from_props, rel_type, to_label, to_props)
  end

  describe "MCP Server module" do
    test "server is defined and running" do
      # Verify the MCP server process is running
      assert Process.whereis(Hermes.Server.Registry) != nil
    end
  end

  describe "Graph queries for tech_stack_recommendation" do
    test "can query technologies recommended for data_dashboard" do
      {:ok, results} =
        Graph.query("""
          MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: 'data_dashboard'})
          RETURN {
            technology: t.name,
            category: t.category
          }
        """)

      assert length(results) > 0

      # Should find Streamlit
      streamlit = Enum.find(results, fn r -> r["technology"] == "Streamlit" end)
      assert streamlit != nil
      assert streamlit["category"] == "framework"
    end

    test "can query vulnerabilities and mitigations" do
      {:ok, results} =
        Graph.query("""
          MATCH (v:Vulnerability {name: 'SQL Injection'})-[:MITIGATED_BY]->(sc:SecurityControl)
          RETURN {
            vulnerability: v.name,
            mitigation: sc.name
          }
        """)

      assert length(results) > 0

      # Should find Parameterized Queries as a mitigation
      param_queries =
        Enum.find(results, fn r ->
          r["mitigation"] == "Parameterized Queries"
        end)

      assert param_queries != nil
    end
  end

  describe "Graph queries for secure_coding_pattern" do
    test "can query best practices for Streamlit" do
      {:ok, results} =
        Graph.query("""
          MATCH (t:Technology {name: 'Streamlit'})-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
          RETURN {
            practice_name: bp.name,
            code_example: bp.code_example
          }
        """)

      assert length(results) > 0

      # Check that code examples exist
      practice = List.first(results)
      assert practice["code_example"] != nil
      assert is_binary(practice["code_example"])
    end

    test "can query best practices with security controls" do
      {:ok, results} =
        Graph.query("""
          MATCH (bp:BestPractice)-[:IMPLEMENTS_CONTROL]->(sc:SecurityControl)
          RETURN {
            practice: bp.name,
            control: sc.name
          }
        """)

      assert length(results) > 0
    end
  end

  describe "Graph queries for deployment_guidance" do
    test "can query deployment patterns for use cases" do
      {:ok, results} =
        Graph.query("""
          MATCH (uc:UseCase {name: 'data_dashboard'})-[:RECOMMENDED_DEPLOYMENT]->(dp:DeploymentPattern)
          RETURN {
            pattern_name: dp.name,
            cost: dp.cost,
            https: dp.https_support
          }
        """)

      assert length(results) > 0

      # Check deployment pattern structure
      pattern = List.first(results)
      assert pattern["pattern_name"] != nil
      assert pattern["cost"] != nil
      https_value = pattern["https"]
      assert https_value in [true, false, "true", "false"]
    end

    test "deployment patterns have required attributes" do
      {:ok, results} =
        Graph.query("""
          MATCH (dp:DeploymentPattern)
          RETURN {
            name: dp.name,
            platform: dp.platform,
            complexity: dp.complexity,
            cost: dp.cost
          }
        """)

      assert length(results) > 0

      pattern = List.first(results)
      assert pattern["name"] != nil
      assert pattern["platform"] != nil
      assert pattern["complexity"] != nil
      assert pattern["cost"] != nil
    end
  end

  describe "Graph data integrity" do
    test "all technologies have required attributes" do
      {:ok, results} =
        Graph.query("""
          MATCH (t:Technology)
          RETURN {
            name: t.name,
            category: t.category,
            description: t.description,
            security_rating: t.security_rating
          }
        """)

      assert length(results) >= 3

      # Check each technology has all required fields
      Enum.each(results, fn tech ->
        assert tech["name"] != nil
        assert tech["category"] != nil
        assert tech["description"] != nil
        assert tech["security_rating"] != nil
      end)
    end

    test "all vulnerabilities have severity levels" do
      {:ok, results} =
        Graph.query("""
          MATCH (v:Vulnerability)
          RETURN {
            name: v.name,
            severity: v.severity
          }
        """)

      assert length(results) >= 2

      Enum.each(results, fn vuln ->
        assert vuln["severity"] in ["critical", "high", "medium", "low"]
      end)
    end

    test "best practices have code examples" do
      {:ok, results} =
        Graph.query("""
          MATCH (bp:BestPractice)
          RETURN {
            name: bp.name,
            code_example: bp.code_example
          }
        """)

      assert length(results) >= 3

      Enum.each(results, fn practice ->
        assert is_binary(practice["code_example"])
        assert String.length(practice["code_example"]) > 0
      end)
    end
  end

  describe "Complex graph traversals" do
    test "can traverse from technology to vulnerabilities to mitigations" do
      {:ok, results} =
        Graph.query("""
          MATCH (t:Technology {name: 'SQLite'})
                -[:HAS_VULNERABILITY]->(v:Vulnerability)
                -[:MITIGATED_BY]->(sc:SecurityControl)
          RETURN {
            tech: t.name,
            vuln: v.name,
            severity: v.severity,
            mitigation: sc.name
          }
        """)

      assert length(results) > 0

      result = List.first(results)
      assert result["tech"] == "SQLite"
      assert result["vuln"] != nil
      assert result["severity"] != nil
      assert result["mitigation"] != nil
    end

    test "can traverse use case to recommended tech to best practices" do
      {:ok, results} =
        Graph.query("""
          MATCH (uc:UseCase {name: 'web_app_small_team'})
                <-[:RECOMMENDED_FOR]-(t:Technology)
                -[:HAS_BEST_PRACTICE]->(bp:BestPractice)
          RETURN {
            use_case: uc.name,
            tech: t.name,
            practice: bp.name
          }
        """)

      assert length(results) > 0
    end
  end

  describe "MCP tool handlers" do
    test "tech stack recommendation handles string-key params and JSON context" do
      {:ok, frame} = Guided.MCPServer.init(%{}, Frame.new())

      params = %{
        "intent" => "Build a data dashboard",
        "context" => ~s({"users": "small_team"})
      }

      {:reply, response, _frame} =
        Guided.MCPServer.handle_tool_call("tech_stack_recommendation", params, frame)

      result = response.structured_content
      assert result[:status] == "success"
      assert result[:use_case] == "data_dashboard"
    end

    test "secure coding pattern handles string-key params" do
      {:ok, frame} = Guided.MCPServer.init(%{}, Frame.new())

      params = %{
        "technology" => "SQLite",
        "task" => "database security"
      }

      {:reply, response, _frame} =
        Guided.MCPServer.handle_tool_call("secure_coding_pattern", params, frame)

      result = response.structured_content
      assert result[:status] == "success"
      assert result[:technology] == "SQLite"
      assert result[:count] >= 1
    end

    test "deployment guidance accepts JSON-encoded stack lists" do
      {:ok, frame} = Guided.MCPServer.init(%{}, Frame.new())

      params = %{
        stack: ~s(["Streamlit", "SQLite"])
      }

      {:reply, response, _frame} =
        Guided.MCPServer.handle_tool_call("deployment_guidance", params, frame)

      result = response.structured_content
      assert result[:status] == "success"

      assert Enum.any?(result[:deployment_patterns], fn pattern ->
               pattern[:name] == "Streamlit Cloud"
             end)
    end

    test "deployment guidance accepts comma-separated stacks" do
      {:ok, frame} = Guided.MCPServer.init(%{}, Frame.new())

      params = %{
        "stack" => "Streamlit, SQLite",
        "requirements" => %{"budget" => "free"}
      }

      {:reply, response, _frame} =
        Guided.MCPServer.handle_tool_call("deployment_guidance", params, frame)

      result = response.structured_content
      assert result[:status] == "success"
      assert result[:recommendation][:name] in ["Streamlit Cloud", "Fly.io Deployment"]
    end
  end
end
