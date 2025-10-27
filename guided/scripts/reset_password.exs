alias Guided.Accounts
alias Guided.Repo

email = "mfreeman451@gmail.com"
password = "Password123!"

user = Repo.get_by(Accounts.User, email: email)

if user do
  # Hash the password and update directly
  hashed = Bcrypt.hash_pwd_salt(password)

  user
  |> Ecto.Changeset.change(%{hashed_password: hashed})
  |> Repo.update!()

  IO.puts("✓ Password updated successfully")
  IO.puts("")
  IO.puts("Login credentials:")
  IO.puts("  Email: #{email}")
  IO.puts("  Password: #{password}")
  IO.puts("")
  IO.puts("Go to: http://localhost:4000/users/log-in")
else
  IO.puts("User not found")
end
