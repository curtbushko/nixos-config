# Converts a shell script to nix by wrapping it.
# The generated script adds itself to home.packages and all you need to do is import the generated script file
#
# Note: isLinux determines if the script only gets added to linux or all systems
{
  # Snowfall Lib provides a customized $(lib) instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of $(pkgs) with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. $(x86_64-linux)).
  target, # The Snowfall Lib target for this system (eg. $(x86_64-iso)).
  format, # A normalized name for the system target (eg. $(iso)).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  convert-sh-to-nix = pkgs.writeShellScriptBin "convert-sh-to-nix" ''
if [ -z "$1" ]; then
	echo "Missing SOURCEFILE argument. Usage: $0 SOURCEFILE DESTDIR"
	exit 1
fi

if [ -z "$2" ]; then
	echo "Missing DESTDIR argument. Usage: $0 SOURCEFILE DESTDIR"
	exit 1
fi

if [ -z "$2" ]; then
	echo "Missing shell script name argument"
	exit 1
fi

SOURCEFILE=$1
DESTDIR=$2
NAME="${SOURCEFILE%.*}"
TEMPFILE=$PWD/tmpfile

echo "Source File: $SOURCEFILE"
echo "Dest Directory: $DESTDIR"
echo "Script Name: $NAME"

# Used for setting prefix and postfix
define() { IFS=$'\n' read -r -d '' ${1} || true; }

define PREFIX <<'EOF'
{
  # Snowfall Lib provides a customized $(lib) instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,
  # An instance of $(pkgs) with your overlays and packages applied is also available.
  pkgs,
  # You also have access to your flake's inputs.
  inputs,
  # Additional metadata is provided by Snowfall Lib.
  system, # The system architecture for this host (eg. $(x86_64-linux)).
  target, # The Snowfall Lib target for this system (eg. $(x86_64-iso)).
  format, # A normalized name for the system target (eg. $(iso)).
  virtual, # A boolean to determine whether this system is a virtual target using nixos-generators.
  systems, # An attribute map of your defined hosts.
  # All other arguments come from the module system.
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  SCRIPTNAME = pkgs.writeShellScriptBin "SCRIPTNAME" ''
EOF

define POSTFIX <<'EOF'
'';
in {
  home.packages =
  [
    SCRIPTNAME
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
EOF

echo "Adding prefix"
echo "$PREFIX" >$TEMPFILE
echo "Adding source file"
cat $SOURCEFILE >>$TEMPFILE
echo "Adding postfix"
echo "$POSTFIX" >>$TEMPFILE

echo "Sed'ing file"
sed -i "s/convert/${NAME}/g" $TEMPFILE

echo "Copying file to $DESTDIR/$NAME.nix"
cp $TEMPFILE $DESTDIR/$NAME.nix

echo "Removing tempfile: $TEMPFILE"
rm $TEMPFILE
'';
in {
  home.packages =
  [
    convert
  ]
  ++ (lib.optionals isLinux [
    # if linux only
  ]);
}
