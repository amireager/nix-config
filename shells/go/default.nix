{
  mkDevShell,
  pkgs,
  ...
}:
mkDevShell {
  name = "go";
  icon = "🐹";
  description = "Go, Gopls, GolangCI-Lint, Air Live-Reload, Delve";

  packages = with pkgs; [
    go
    gopls
    golangci-lint
    air # Live reload for Go applications
    delve # Go debugger
  ];

  tips = [
    {
      key = "Live Reload";
      cmd = "air";
    }
    {
      key = "Run & Build";
      cmd = "go run . / go build";
    }
    {
      key = "Lint";
      cmd = "golangci-lint run";
    }
    {
      key = "Test";
      cmd = "go test ./...";
    }
  ];
}
