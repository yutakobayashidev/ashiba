# PCB design

KiCadの安定版による回路図・基板設計の環境です。`kicad` で起動します。固定中のnixpkgsではDarwin版がbroken指定のため、Linux x86_64だけを対象にします。

KiCadプロジェクト・回路図・基板・ライブラリをGitで管理し、製造用のGerber・ドリルファイルを `exports/` に出力します。ERC / DRCの結果を確認してから製造データを作成してください。

## 開始

```bash
nix flake init -t github:yutakobayashidev/ashiba#pcb
git add flake.nix flake.lock skills .envrc .gitignore AGENTS.md README.md
nix develop
```

Linux x86_64に対応します。flake-partsを使い、設定は `flake.nix` にまとめています。
用途をまたぐ場合は、そのプロジェクトの `devShells.default.packages` に必要なパッケージを追加します。複数テンプレートを同じディレクトリに初期化する必要はありません。

## Agent Skills

agent-skills-nixが付属の `skills/pcb-workflow/SKILL.md` をshell起動時に
`.agents/skills`・`.codex/skills`・`.claude/skills`・`.opencode/skills` へ配備します。
Piは `.agents/skills` を共用します。編集は生成先ではなく `skills/` の原本へ行ってください。

## 更新と検証

`nix flake update` で依存を更新し、`nix flake check` でshell評価とSkills配備を確認します。
各プロジェクトのビルド・設計・製造結果は別途検証してください。
