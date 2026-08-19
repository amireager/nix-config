# Pure shell registry shared by Flake outputs, the launcher, and completions.
# Keep this file dependency-free: it is source data plus lightweight invariants.
let
  registry = {
    shellDirs = [
      "agent"
      "ai"
      "audit"
      "build"
      "cli"
      "go"
      "media"
      "net"
      "nix"
      "python"
      "rust"
      "web"
    ];

    groups = [
      {
        title = "AI & Autonomous Agents";
        members = ["agent" "ai"];
      }
      {
        title = "Languages, Data & Runtimes";
        members = ["python" "rust" "go" "web"];
      }
      {
        title = "Media & Content";
        members = ["media"];
      }
      {
        title = "System, Build & QA";
        members = ["cli" "build" "nix"];
      }
      {
        title = "Network & Security";
        members = ["net" "audit"];
      }
    ];

    aliases = {
      c = "build";
      data = "python";
      default = "nix";
    };
  };

  unique = values:
    builtins.attrNames (builtins.listToAttrs (map (name: {
        inherit name;
        value = true;
      })
      values));
  duplicates = values:
    builtins.filter
    (name: builtins.length (builtins.filter (value: value == name) values) > 1)
    (unique values);
  validName = name: builtins.match "[a-z][a-z0-9-]*" name != null;
  show = values: builtins.concatStringsSep ", " values;

  shellNames = registry.shellDirs;
  aliasNames = builtins.attrNames registry.aliases;
  groupTitles = map (group: group.title) registry.groups;
  groupMembers = builtins.concatLists (map (group: group.members) registry.groups);

  duplicateShells = duplicates shellNames;
  invalidShells = builtins.filter (name: !(validName name)) shellNames;
  emptyGroups = builtins.filter (group: group.title == "" || group.members == []) registry.groups;
  duplicateGroups = duplicates groupTitles;
  unknownMembers = builtins.filter (name: !(builtins.elem name shellNames)) (unique groupMembers);
  ungroupedShells = builtins.filter (name: !(builtins.elem name groupMembers)) shellNames;
  repeatedMembers = duplicates groupMembers;
  invalidAliases = builtins.filter (name: !(validName name)) aliasNames;
  unknownAliasTargets = builtins.filter
    (name: !(builtins.elem registry.aliases.${name} shellNames))
    aliasNames;
  aliasCollisions = builtins.filter (name: builtins.elem name shellNames) aliasNames;
in
  assert builtins.length shellNames > 0;
  assert builtins.length registry.groups > 0;
  assert duplicateShells == [] || throw "devShell registry: duplicate shell names: ${show duplicateShells}";
  assert invalidShells == [] || throw "devShell registry: invalid shell names: ${show invalidShells}";
  assert emptyGroups == [] || throw "devShell registry: group titles and member lists must be non-empty";
  assert duplicateGroups == [] || throw "devShell registry: duplicate group titles: ${show duplicateGroups}";
  assert unknownMembers == [] || throw "devShell registry: unknown group members: ${show unknownMembers}";
  assert ungroupedShells == [] || throw "devShell registry: ungrouped shells: ${show ungroupedShells}";
  assert repeatedMembers == [] || throw "devShell registry: shells in more than one group: ${show repeatedMembers}";
  assert invalidAliases == [] || throw "devShell registry: invalid aliases: ${show invalidAliases}";
  assert unknownAliasTargets == [] || throw "devShell registry: aliases with unknown targets: ${show unknownAliasTargets}";
  assert aliasCollisions == [] || throw "devShell registry: aliases collide with shell names: ${show aliasCollisions}";
  registry
