import Config

config :monc, repo: Monc.Repo

config :logger, level: :warning

config :monc,
  ecto_repos: [Monc.Repo]
