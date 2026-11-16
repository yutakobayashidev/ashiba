# Native reverse engineering

Ghidra CLIと、そのCLIと同じソースリビジョンの公式Skillを使うLinux x86_64環境です。
GhidraのGUIやMCPサーバーを起動せず、Agentから逆コンパイル・検索・注釈編集を行えます。

```bash
nix flake init -t github:yutakobayashidev/ashiba#reverse-native
git add flake.nix flake.lock .envrc .gitignore AGENTS.md README.md
nix develop
ghidra-cli doctor --runtime
ghidra-cli program import ./target.bin --project target --name target.bin
ghidra-cli decompile main --project target --program target.bin --json
ghidra-cli bridge stop --project target
```

プロジェクトルートからshellに入り、Agentはその後で起動してください。
CLIとGhidra・JDKはNURの固定されたパッケージを使います。CLIを更新するときは
`nix flake update ashiba` を使います。公式Skillは同じパッケージのソースから取得します。

解析DBは `analysis/projects/`、CLIの設定・キャッシュ・ログは `analysis/runtime/` に保存します。
Ghidra 12.1以降ではDBパスにドットで始まるディレクトリを含めないでください。
プロジェクトルート自体にもこの制約があります。元のバイナリとレポートは別途保存してください。

shell終了時にJVM bridgeは自動停止しません。作業終了時に `bridge stop` を実行します。
同じDBをGUIで開く前やGhidraを更新する前にもbridgeを停止してください。
CLI用ラッパー内だけでXDGパスを設定し、他の開発ツールの設定先は変更しません。

## 既存のflake-partsプロジェクトへ追加

`ashiba` をflake inputに追加し、mkFlake内で次のmoduleをimportします。

```nix
imports = [ inputs.ashiba.flakeModules.reverse-native ];
```

このmoduleはnumtide/devshellの `perSystem.devshells.default` にCLIを追加します。
他のツールも `perSystem.devshells.default.packages` へ追加できます。
既存の `devShells.default = pkgs.mkShell { ... };` は同時に定義せず、
同じ `devshells.default` の設定へ移してください。

公式Skillを `.agents/skills`・`.codex/skills`・`.claude/skills`・`.opencode/skills` へ配備します。
既に別のSkills同期処理があるプロジェクトでは、同じ配備先への別々の同期を重ねず、
選択をまとめて1回同期するよう統合してください。

## 検証

`nix flake check` でshell評価と公式Skill配備を確認します。
実行環境は `doctor --runtime` と、対象バイナリのimport・decompileで確認してください。
このshellはツール環境を提供し、解析対象をVMのように隔離するものではありません。
