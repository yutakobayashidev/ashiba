# 3D printing

PrusaSlicerでスライスと印刷準備をする環境です。Linuxは `prusa-slicer`、macOSは `printing-prusa-slicer` で起動します。

プリンタ・ノズル・材料・校正済みプロファイルを選び、3MFプロジェクトと設定を保存します。向き・サポート・ツールパスを確認し、G-codeを `exports/` に出力します。形状の編集は `cad` テンプレートで扱います。shell起動時に印刷を開始しません。

## 開始

```bash
nix flake init -t github:yutakobayashidev/ashiba#printing
git add flake.nix flake.lock skills .envrc .gitignore AGENTS.md README.md
nix develop
```

Linux x86_64とApple Silicon macOSに対応します。flake-partsを使い、設定は `flake.nix` にまとめています。
用途をまたぐ場合は、そのプロジェクトの `devShells.default.packages` に必要なパッケージを追加します。複数テンプレートを同じディレクトリに初期化する必要はありません。

## Agent Skills

agent-skills-nixが付属の `skills/printing-workflow/SKILL.md` をshell起動時に
`.agents/skills`・`.codex/skills`・`.claude/skills`・`.opencode/skills` へ配備します。
Piは `.agents/skills` を共用します。編集は生成先ではなく `skills/` の原本へ行ってください。

## 更新と検証

`nix flake update` で依存を更新し、`nix flake check` でshell評価とSkills配備を確認します。
各プロジェクトのビルド・設計・製造結果は別途検証してください。

macOSのGUIはbrew-nixで取得し、付属ランチャーから起動します。GUIのユーザー設定は隔離しません。Linuxは既存のWayland / X11セッションを使います。
