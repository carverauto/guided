alias Guided.Accounts
alias Guided.Repo

email = "test@test.com"
password = "TestPassword123!"

# Delete if exists
case Repo.get_by(Accounts.User, email: email) do
  nil -> :ok
  user -> Repo.delete!(user)
end

# Create new user
{:ok, user} = Accounts.register_user(%{email: email, password: password})

# Confirm immediately
user
|> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
|> Repo.update!()

IO.puts("\n✓ Fresh test account created!\n")
IO.puts("Login credentials:")
IO.puts("  Email: #{email}")
IO.puts("  Password: #{password}")
IO.puts("\nGo to: http://localhost:4000/users/log-in\n")
