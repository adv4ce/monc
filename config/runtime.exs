import Config

if Config.config_env() == :dev, do: DotenvParser.load_file(".env")

config :monc, Monc.Repo,
  database: System.fetch_env!("POSTGRES_DBNAME"),
  username: System.fetch_env!("POSTGRES_USERNAME"),
  password: System.fetch_env!("POSTGRES_PASSWORD"),
  hostname: System.fetch_env!("POSTGRES_HOST"),
  port: System.fetch_env!("POSTGRES_PORT")
