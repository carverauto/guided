alias Guided.Repo
alias Guided.Accounts.User

# Fix both accounts with proper passwords
accounts = [
  {"mfreeman451@gmail.com", "Password123!"},
  {"test@test.com", "TestPassword123!"}
]

IO.puts("\nFixing account passwords...\n")

Enum.each(accounts, fn {email, password} ->
  user = Repo.get_by(User, email: email)

  if user do
    hashed = Bcrypt.hash_pwd_salt(password)

    user
    |> Ecto.Changeset.change(%{
      hashed_password: hashed,
      confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update!()

    IO.puts("✓ #{email} - password set and confirmed")
  end
end)

IO.puts("\n✓ All accounts fixed!\n")
IO.puts("Login with:")
IO.puts("  Email: mfreeman451@gmail.com")
IO.puts("  Password: Password123!")
IO.puts("\nOR\n")
IO.puts("  Email: test@test.com")
IO.puts("  Password: TestPassword123!")
IO.puts("\nGo to: http://localhost:4000/users/log-in\n")
