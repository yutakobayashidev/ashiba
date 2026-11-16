# Android reverse engineering

APK解析・Android CTF向けのLinux x86_64環境です。JADX、Apktool、Frida tools、
ADBと、解析手順のSkillを配布します。SDK・エミュレータは含みません。

```bash
nix flake init -t github:yutakobayashidev/ashiba#reverse-android
nix develop
jadx --version
apktool --version
frida --version
```

元APKのハッシュと入手元を記録し、新しい出力先へ展開します。
動的解析には別途テスト端末と、ホストFridaのバージョン・端末ABIに合う
frida-serverが必要です。shell起動時に端末への転送や起動はしません。

`.so`を調べる場合は `flake.nix` のimportsへ
`inputs.ashiba.flakeModules.reverse-native` を追加します。
エミュレータやビルド環境も必要なら `inputs.ashiba.flakeModules.android` を追加し、
`perSystem.ashiba.android.acceptLicense = true;` を設定します。
SDKライセンスの受諾により、解析用AOSP AVDとMaestroを使える環境になります。

各moduleのSkillはagent-skills-nixがまとめて1回同期します。
独自Skillも `perSystem.ashiba.skills.sources` と `selection` に追加できます。
`.agents/skills`・`.codex/skills`・`.claude/skills`・`.opencode/skills`は配布先です。
Agentはshellに入った後で起動してください。

`nix flake update ashiba`でmoduleと付属Skillを更新します。
