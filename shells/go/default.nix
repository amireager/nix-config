{mkDevShell, pkgs, ...}:
mkDevShell {
  name = "go";
  icon = "🐹";
  description = "Go, Gopls, GolangCI-Lint, Delve";

  packages = with pkgs; [
    go
    gopls
    golangci-lint
    delve # Go debugger
  ];

  tips = [
    {key = "Run & Build"; cmd = "go run . / go build";}
    {key = "Lint"; cmd = "golangci-lint run";}
    {key = "Test"; cmd = "go test ./...";}
  ];
}
