function ws
  if test -z "$argv[1]"
      echo "No customer provided."
      return 1
  end
  docker compose --env-file $HOME/dev-container/envs/$argv[1].env run --rm workspace zsh
  # code --folder-uri vscode-remote://attached-container+$(docker ps -lq)/home/workspace
end
