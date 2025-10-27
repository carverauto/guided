alias Guided.Accounts
alias Guided.Repo

email = "mfreeman451@gmail.com"
password = "abc123"

user = Repo.get_by(Accounts.User, email: email)

if user do
  IO.puts("Found user: #{email}")

  # Hash the password
  hashed_password = Bcrypt.hash_pwd_salt(password)

  # Update user with password and confirm
  user
  |> Ecto.Changeset.change(%{
    hashed_password: hashed_password,
    confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
  })
  |> Repo.update!()

  IO.puts("✓ Password updated to: #{password}")
  IO.puts("✓ Account confirmed")
else
  IO.puts("User not found, creating new account...")

  case Accounts.register_user(%{email: email, password: password}) do
    {:ok, user} ->
      # Confirm the user
      user
      |> Ecto.Changeset.change(%{confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      |> Repo.update!()

      IO.puts("✓ Created user: #{email}")
      IO.puts("✓ Password set to: #{password}")
    {:error, changeset} ->
      IO.puts("Error creating user:")
      IO.inspect(changeset.errors)
  end
end
