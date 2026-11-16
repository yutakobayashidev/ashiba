# CAD design

FreeCADとOpenSCADによる形状設計の環境です。LinuxのFreeCADはstable入力を使います。Linuxは `FreeCAD`、macOSは `cad-freecad` で起動します。OpenSCADは両方で `openscad` を使います。

`.FCStd`・`.scad` を原本として保存し、STL・STEPを `exports/` に出力します。寸法・単位・公差と出力形状を確認してください。スライスは別の `printing` テンプレートで扱います。

## 開始

```bash
nix flake init -t github:yutakobayashidev/ashiba#cad
git add flake.nix flake.lock skills .envrc .gitignore AGENTS.md README.md
nix develop
```

Linux x86_64とApple Silicon macOSに対応します。flake-partsを使い、設定は `flake.nix` にまとめています。
用途をまたぐ場合は、そのプロジェクトの `devShells.default.packages` に必要なパッケージを追加します。複数テンプレートを同じディレクトリに初期化する必要はありません。

## Agent Skills

agent-skills-nixが付属の `skills/cad-workflow/SKILL.md` をshell起動時に
`.agents/skills`・`.codex/skills`・`.claude/skills`・`.opencode/skills` へ配備します。
Piは `.agents/skills` を共用します。編集は生成先ではなく `skills/` の原本へ行ってください。

## 更新と検証

`nix flake update` で依存を更新し、`nix flake check` でshell評価とSkills配備を確認します。
各プロジェクトのビルド・設計・製造結果は別途検証してください。

macOSのGUIはbrew-nixで取得し、付属ランチャーから起動します。GUIのユーザー設定は隔離しません。Linuxは既存のWayland / X11セッションを使います。
