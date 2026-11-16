# Native CTF / pwn

Linux x86_64のCTF用環境です。ツールとpwn用Skillをプロジェクト単位で配布します。

```bash
nix flake init -t github:yutakobayashidev/ashiba#pwn
# Git管理中ならflakeを追加してから入る
git add flake.nix flake.lock
nix develop
```

| shell | 内容 |
| --- | --- |
| `nix develop` | GDB、GEF、pwntools、ptrlib、Ropper、ROPgadget、one_gadget、pwninit、checksec、binutils、patchelf、file、QEMU、strace、ltrace |
| `nix develop .#full` | 上記＋Ghidra CLIと対応する公式Skill |

`gef`はGEFを読み込むGDBランチャーです。`~/.gdbinit`は変更しません。
自分のGDB設定も読み込ませたくない場合は `gdb -nx` / `gef -nx` を使います。
Pythonライブラリは同じインタープリタにまとめ、`python3`から利用できます。
単独の `checksec` を優先し、pwntoolsのCLIは `pwn checksec` で呼び分けます。

```bash
file ./challenge
readelf -h ./challenge
checksec --help
gdb -nx ./challenge
gef -nx ./challenge
python3 -c 'from pwn import ELF; print(ELF("./challenge").arch)'
ROPgadget --binary ./challenge --only 'ret'
```

元バイナリ・libc・loaderは保存し、pwninitやpatchelfは作業用コピーで実行します。
QEMUを入れてもホストのKVMサービスや権限は変更されません。異なるABIの実行には
対象のライブラリも必要です。ptrace制限がある環境ではデバッグが失敗する場合があります。
このshellは実行対象やネットワークを隔離しません。

## 既存flake-parts環境へ追加

ashibaをinputへ追加し、mkFlake内に指定します。

```nix
imports = [
  inputs.ashiba.flakeModules.pwn
  inputs.ashiba.flakeModules.reverse-native # 必要な場合
];
```

追加パッケージは `perSystem.devshells.default.packages` へ設定します。
Skillは既存の共有moduleがまとめて1回配布します。Agentはshellに入ってから起動します。
独自Skillの原本は `skills/` に置き、`perSystem.ashiba.skills` に登録してください。
生成先の `.agents/skills` 等は選択内容のミラーで、直接編集する場所ではありません。

`nix flake update nixpkgs`でツール群、`nix flake update ashiba`でmoduleとSkillを更新します。
`full`で起動したGhidra bridgeは、作業終了時に `ghidra-cli bridge stop --project NAME`
で停止してください。
