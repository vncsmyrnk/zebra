[![GitHub main branch check runs](https://img.shields.io/github/check-runs/vncsmyrnk/zebra/main?style=plastic&logo=github&label=CI%20workflow)](https://github.com/vncsmyrnk/zebra/actions/workflows/ci.yaml)

A rewrite of GNU coreutils `cat` for educational purposes.

## Examples

```sh
diff <(echo "1\n2\n3" | zebra) <(echo "1\n2\n3" | cat) && echo "reads from standard input."
diff <(zebra ./LICENSE ./build.zig) <(cat ./LICENSE ./build.zig) && echo "reads files from arguments."
```

## Run

```sh
zig build
./zig-out/bin/zebra --help
```
