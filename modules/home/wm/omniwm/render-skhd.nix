# Null process actions pass the shortcut through to the application.
bindings:
builtins.concatStringsSep "\n" (map (key: let
  action = bindings.${key};
in
  if builtins.isAttrs action
  then "${key} [\n${builtins.concatStringsSep "\n" (map (process: let
    name =
      if process == "*"
      then "*"
      else ''"${process}"'';
    command =
      if action.${process} == null
      then "~"
      else ": ${action.${process}}";
  in "  ${name} ${command}") (builtins.attrNames action))}\n]"
  else "${key} : ${action}") (builtins.attrNames bindings))
