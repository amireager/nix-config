{mkDevShell, pkgs, ...}:
mkDevShell {
  name = "data";
  icon = "📊";
  description = "Pandas, NumPy, DuckDB, Jupyter";

  packages = with pkgs; [
    python3
    python3Packages.pandas
    python3Packages.numpy
    python3Packages.ipython
    python3Packages.jupyterlab
    duckdb
    sqlite
    jq
  ];

  tips = [
    {key = "Jupyter Lab"; cmd = "jupyter lab";}
    {key = "DuckDB / SQL"; cmd = "duckdb / sqlite3";}
    {key = "REPL"; cmd = "ipython";}
  ];
}
