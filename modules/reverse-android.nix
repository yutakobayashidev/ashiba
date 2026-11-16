{ inputs }:
{
  imports = [ (import ./skills.nix { inherit inputs; }) ];
  perSystem =
    { pkgs, ... }:
    {
      ashiba = {
        reverseAndroid = true;
        skills = {
          sources.reverse-android.path = ../skills;
          selection.reverse-android = {
            from = "reverse-android";
            path = "reverse-android";
            rewriteCommands = false;
          };
        };
      };
      devshells.default.packages = with pkgs; [
        jadx
        apktool
        frida-tools
        android-tools
      ];
    };
}
