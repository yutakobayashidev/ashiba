# Firmware development

Arduino CLIとPlatformIOの環境です。

`nix develop .#ide` でArduino IDEも追加できます。Linuxは `arduino-ide`、macOSは `firmware-arduino-ide` で起動します。

`arduino-cli config dump`、`arduino-cli board list`、`pio --version` で確認します。CLIのキャッシュは `.firmware/`、Arduinoのユーザースケッチ領域は `firmware/arduino` です。Arduino IDEの既存設定とは別になる場合があります。

ボード・SDK・依存ライブラリは `sketch.yaml` または `platformio.ini` で固定します。`arduino-cli compile --profile <profile> <sketch-directory>` または `pio run` でビルドします。初回の依存取得にはネット接続が必要です。

LinuxのCLIはnixpkgsのFHSラッパーを使うため、ユーザー名前空間を禁止したコンテナでは起動できません。USB・シリアル権限はホスト側で設定してください。NixOSでは必要に応じてユーザーの `dialout` グループと `services.udev.packages = [ pkgs.platformio-core.udev ];` を設定します。shell起動時の書き込みは行いません。

## 開始

```bash
nix flake init -t github:yutakobayashidev/ashiba#firmware
git add flake.nix flake.lock skills .envrc .gitignore AGENTS.md README.md
nix develop
```

Linux x86_64とApple Silicon macOSに対応します。flake-partsを使い、設定は `flake.nix` にまとめています。
用途をまたぐ場合は、そのプロジェクトの `devShells.default.packages` に必要なパッケージを追加します。複数テンプレートを同じディレクトリに初期化する必要はありません。

## Agent Skills

agent-skills-nixが付属の `skills/firmware-workflow/SKILL.md` をshell起動時に
`.agents/skills`・`.codex/skills`・`.claude/skills`・`.opencode/skills` へ配備します。
Piは `.agents/skills` を共用します。編集は生成先ではなく `skills/` の原本へ行ってください。

## 更新と検証

`nix flake update` で依存を更新し、`nix flake check` でshell評価とSkills配備を確認します。
各プロジェクトのビルド・設計・製造結果は別途検証してください。
