# Common helper functions for nix-config
{lib, ...}: {
  # Recursively read directory and return attribute set
  # Usage: readDirRecursive ./path → {"file.nix" = ..., "dir/file.nix" = ...}
  readDirRecursive = path:
    let
      entries = builtins.readDir path;
      process = name: type:
        if type == "regular" then
          {"${name}" = path + "/${name}";}
        else if type == "directory" then
          let
            subDir = lib.helpers.readDirRecursive (path + "/${name}");
          in
            lib.mapAttrs' (n: v: lib.nameValuePair "${name}/${n}" v) subDir
        else
          {};
    in
      lib.foldAttrs lib.recursiveUpdate {} (lib.mapAttrsToList process entries);

  # Deep merge two attribute sets (second overrides first)
  deepMerge = lib.recursiveUpdate;

  # Get value from nested attribute set with default
  # Usage: getPath "a.b.c" {a.b.c = 1;} "default" → 1
  getPath = path: attrs: default:
    let
      parts = lib.splitString "." path;
      result = lib.attrByPath parts null attrs;
    in
      if result == null then default else result;

  # Validate required keys in an attribute set
  # Usage: validateKeys ["hostname" "modules"] config → throw if missing
  validateKeys = required: attrs:
    let
      missing = lib.filter (k: !lib.hasAttr k attrs) required;
    in
      if missing != [] then
        throw "Missing required keys: ${lib.concatStringsSep ", " missing}"
      else
        true;
}
