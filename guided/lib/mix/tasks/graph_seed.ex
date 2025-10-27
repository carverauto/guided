defmodule Mix.Tasks.Graph.Seed do
  @moduledoc """
  Seeds the graph database with initial knowledge for the guided.dev MVP.

  This populates the graph with foundational knowledge about Python web development,
  with a strong emphasis on security (OWASP Top 10).

  Run with: mix graph.seed
  """

  use Mix.Task
  alias Guided.Graph

  @shortdoc "Seeds the graph database with initial knowledge"

  def run(_args) do
    Mix.Task.run("app.start")

    Mix.shell().info("Seeding guided.dev knowledge graph...")

    # Clear existing data (for development)
    clear_graph()

    # Seed in order of dependencies
    seed_technologies()
    seed_use_cases()
    seed_vulnerabilities()
    seed_security_controls()
    seed_best_practices()
    seed_deployment_patterns()

    # Create relationships
    create_relationships()

    Mix.shell().info("\n✓ Graph seeding completed successfully!")
    show_stats()
  end

  defp clear_graph do
    Mix.shell().info("Clearing existing graph data...")
    {:ok, _} = Graph.query("MATCH (n) DETACH DELETE n")
  end

  defp seed_technologies do
    Mix.shell().info("Seeding technologies...")

    technologies = [
      %{
        name: "Python",
        category: "language",
        version: "3.11+",
        description: "High-level programming language",
        maturity: "mature",
        security_rating: "good"
      },
      %{
        name: "Streamlit",
        category: "framework",
        version: "1.28+",
        description: "Python framework for building data apps",
        maturity: "stable",
        security_rating: "good"
      },
      %{
        name: "SQLite",
        category: "database",
        version: "3.x",
        description: "Lightweight embedded SQL database",
        maturity: "mature",
        security_rating: "good"
      },
      %{
        name: "FastAPI",
        category: "framework",
        version: "0.104+",
        description: "Modern Python web framework",
        maturity: "stable",
        security_rating: "excellent"
      }
    ]

    Enum.each(technologies, fn tech ->
      {:ok, _} = Graph.create_node("Technology", tech)
    end)
  end

  defp seed_use_cases do
    Mix.shell().info("Seeding use cases...")

    use_cases = [
      %{
        name: "web_app_small_team",
        description: "Web application for small team or personal use",
        user_scale: "1-100",
        complexity: "low"
      },
      %{
        name: "data_dashboard",
        description: "Interactive data visualization dashboard",
        user_scale: "1-1000",
        complexity: "low"
      },
      %{
        name: "api_service",
        description: "RESTful API service",
        user_scale: "variable",
        complexity: "medium"
      }
    ]

    Enum.each(use_cases, fn use_case ->
      {:ok, _} = Graph.create_node("UseCase", use_case)
    end)
  end

  defp seed_vulnerabilities do
    Mix.shell().info("Seeding vulnerabilities...")

    vulnerabilities = [
      %{
        name: "SQL Injection",
        owasp_rank: "A03:2021",
        severity: "critical",
        description: "Injection of malicious SQL code through user input",
        cwe: "CWE-89"
      },
      %{
        name: "Cross-Site Scripting (XSS)",
        owasp_rank: "A03:2021",
        severity: "high",
        description: "Injection of malicious scripts into web pages",
        cwe: "CWE-79"
      },
      %{
        name: "Insecure Authentication",
        owasp_rank: "A07:2021",
        severity: "critical",
        description: "Weak or broken authentication mechanisms",
        cwe: "CWE-287"
      },
      %{
        name: "Path Traversal",
        owasp_rank: "A01:2021",
        severity: "high",
        description: "Unauthorized access to files outside intended directory",
        cwe: "CWE-22"
      }
    ]

    Enum.each(vulnerabilities, fn vuln ->
      {:ok, _} = Graph.create_node("Vulnerability", vuln)
    end)
  end

  defp seed_security_controls do
    Mix.shell().info("Seeding security controls...")

    controls = [
      %{
        name: "Parameterized Queries",
        category: "input_validation",
        description: "Use prepared statements to prevent SQL injection",
        implementation_difficulty: "low"
      },
      %{
        name: "Input Sanitization",
        category: "input_validation",
        description: "Validate and sanitize all user inputs",
        implementation_difficulty: "medium"
      },
      %{
        name: "Output Encoding",
        category: "output_handling",
        description: "Encode output to prevent XSS attacks",
        implementation_difficulty: "low"
      },
      %{
        name: "Strong Password Policy",
        category: "authentication",
        description: "Enforce strong passwords with complexity requirements",
        implementation_difficulty: "low"
      },
      %{
        name: "Multi-Factor Authentication",
        category: "authentication",
        description: "Require multiple authentication factors",
        implementation_difficulty: "medium"
      },
      %{
        name: "Path Validation",
        category: "input_validation",
        description: "Validate file paths to prevent traversal",
        implementation_difficulty: "low"
      }
    ]

    Enum.each(controls, fn control ->
      {:ok, _} = Graph.create_node("SecurityControl", control)
    end)
  end

  defp seed_best_practices do
    Mix.shell().info("Seeding best practices...")

    practices = [
      %{
        name: "Use SQLAlchemy with Parameterized Queries",
        technology: "Python-SQLite",
        category: "database_security",
        description: "Always use SQLAlchemy ORM or parameterized queries for database operations",
        code_example: "session.query(User).filter(User.name == user_input)  # Safe"
      },
      %{
        name: "Streamlit Secret Management",
        technology: "Streamlit",
        category: "configuration",
        description: "Use st.secrets for sensitive configuration",
        code_example: "db_password = st.secrets['database']['password']"
      },
      %{
        name: "Enable Streamlit CORS Protection",
        technology: "Streamlit",
        category: "security_config",
        description: "Configure CORS properly in Streamlit config",
        code_example: "[server]\\nenableCORS = true\\nenableXsrfProtection = true"
      },
      %{
        name: "Validate User Inputs in Forms",
        technology: "Streamlit",
        category: "input_validation",
        description: "Always validate user inputs from text_input, number_input, etc.",
        code_example: "if user_input and len(user_input) < 100: ..."
      }
    ]

    Enum.each(practices, fn practice ->
      {:ok, _} = Graph.create_node("BestPractice", practice)
    end)
  end

  defp seed_deployment_patterns do
    Mix.shell().info("Seeding deployment patterns...")

    patterns = [
      %{
        name: "Streamlit Cloud",
        platform: "streamlit_cloud",
        cost: "free_tier_available",
        complexity: "low",
        description: "Official Streamlit hosting platform",
        https_support: true
      },
      %{
        name: "Docker Container",
        platform: "containerized",
        cost: "varies",
        complexity: "medium",
        description: "Deploy as Docker container to any cloud provider",
        https_support: true
      },
      %{
        name: "Fly.io Deployment",
        platform: "fly_io",
        cost: "free_tier_available",
        complexity: "low",
        description: "Deploy to Fly.io with automatic HTTPS",
        https_support: true
      }
    ]

    Enum.each(patterns, fn pattern ->
      {:ok, _} = Graph.create_node("DeploymentPattern", pattern)
    end)
  end

  defp create_relationships do
    Mix.shell().info("Creating relationships...")

    # Technology -> UseCase (RECOMMENDED_FOR)
    create_rel("Technology", %{name: "Streamlit"}, "RECOMMENDED_FOR", "UseCase", %{name: "data_dashboard"})
    create_rel("Technology", %{name: "Streamlit"}, "RECOMMENDED_FOR", "UseCase", %{name: "web_app_small_team"})
    create_rel("Technology", %{name: "FastAPI"}, "RECOMMENDED_FOR", "UseCase", %{name: "api_service"})
    create_rel("Technology", %{name: "SQLite"}, "RECOMMENDED_FOR", "UseCase", %{name: "web_app_small_team"})

    # Technology -> Vulnerability (HAS_VULNERABILITY)
    create_rel("Technology", %{name: "SQLite"}, "HAS_VULNERABILITY", "Vulnerability", %{name: "SQL Injection"})
    create_rel("Technology", %{name: "Streamlit"}, "HAS_VULNERABILITY", "Vulnerability", %{name: "Cross-Site Scripting (XSS)"})
    create_rel("Technology", %{name: "Streamlit"}, "HAS_VULNERABILITY", "Vulnerability", %{name: "Path Traversal"})

    # Vulnerability -> SecurityControl (MITIGATED_BY)
    create_rel("Vulnerability", %{name: "SQL Injection"}, "MITIGATED_BY", "SecurityControl", %{name: "Parameterized Queries"})
    create_rel("Vulnerability", %{name: "SQL Injection"}, "MITIGATED_BY", "SecurityControl", %{name: "Input Sanitization"})
    create_rel("Vulnerability", %{name: "Cross-Site Scripting (XSS)"}, "MITIGATED_BY", "SecurityControl", %{name: "Output Encoding"})
    create_rel("Vulnerability", %{name: "Cross-Site Scripting (XSS)"}, "MITIGATED_BY", "SecurityControl", %{name: "Input Sanitization"})
    create_rel("Vulnerability", %{name: "Insecure Authentication"}, "MITIGATED_BY", "SecurityControl", %{name: "Strong Password Policy"})
    create_rel("Vulnerability", %{name: "Insecure Authentication"}, "MITIGATED_BY", "SecurityControl", %{name: "Multi-Factor Authentication"})
    create_rel("Vulnerability", %{name: "Path Traversal"}, "MITIGATED_BY", "SecurityControl", %{name: "Path Validation"})

    # BestPractice -> SecurityControl (IMPLEMENTS_CONTROL)
    create_rel("BestPractice", %{name: "Use SQLAlchemy with Parameterized Queries"}, "IMPLEMENTS_CONTROL", "SecurityControl", %{name: "Parameterized Queries"})
    create_rel("BestPractice", %{name: "Validate User Inputs in Forms"}, "IMPLEMENTS_CONTROL", "SecurityControl", %{name: "Input Sanitization"})
    create_rel("BestPractice", %{name: "Enable Streamlit CORS Protection"}, "IMPLEMENTS_CONTROL", "SecurityControl", %{name: "Output Encoding"})

    # Technology -> BestPractice (HAS_BEST_PRACTICE)
    create_rel("Technology", %{name: "Streamlit"}, "HAS_BEST_PRACTICE", "BestPractice", %{name: "Streamlit Secret Management"})
    create_rel("Technology", %{name: "Streamlit"}, "HAS_BEST_PRACTICE", "BestPractice", %{name: "Enable Streamlit CORS Protection"})
    create_rel("Technology", %{name: "Streamlit"}, "HAS_BEST_PRACTICE", "BestPractice", %{name: "Validate User Inputs in Forms"})
    create_rel("Technology", %{name: "SQLite"}, "HAS_BEST_PRACTICE", "BestPractice", %{name: "Use SQLAlchemy with Parameterized Queries"})

    # UseCase -> DeploymentPattern (recommended deployments)
    create_rel("UseCase", %{name: "web_app_small_team"}, "RECOMMENDED_DEPLOYMENT", "DeploymentPattern", %{name: "Streamlit Cloud"})
    create_rel("UseCase", %{name: "data_dashboard"}, "RECOMMENDED_DEPLOYMENT", "DeploymentPattern", %{name: "Streamlit Cloud"})
    create_rel("UseCase", %{name: "web_app_small_team"}, "RECOMMENDED_DEPLOYMENT", "DeploymentPattern", %{name: "Fly.io Deployment"})
  end

  defp create_rel(from_label, from_props, rel_type, to_label, to_props) do
    case Graph.create_relationship(from_label, from_props, rel_type, to_label, to_props) do
      {:ok, _} -> :ok
      {:error, error} ->
        Mix.shell().error("Failed to create relationship #{from_label} -> #{rel_type} -> #{to_label}: #{inspect(error)}")
    end
  end

  defp show_stats do
    # AGE returns simple integers for count(), not maps
    {:ok, [node_count]} = Graph.query("MATCH (n) RETURN count(n)")
    {:ok, [edge_count]} = Graph.query("MATCH ()-[r]->() RETURN count(r)")

    Mix.shell().info("\nGraph Statistics:")
    Mix.shell().info("  Nodes: #{node_count}")
    Mix.shell().info("  Edges: #{edge_count}")
  end
end
