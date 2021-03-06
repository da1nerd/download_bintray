# download_bintray

JFrog is sunsetting Bintray on May 1, 2021 (see the [community announcement](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/)).
I couldn't find a simple way to backup all of my artifacts so I wrote this small client to download everything.

> Note: I initially attempted to use `wget` for a recursive directory download, but bintray formatted the links in a funny way (probably to avoid people doing exactly that).

This was written in haste and has a limited life span and use-case, so the code is quit ugly and I have no intention of changing that.
PRs welcome!

## Installation

```bash
shards build
```

This will compile and place the binary in `./bin`

## Usage

Run the executable with `--help` to get a list of options.
The following will download all of the artifacts of `someuser` from `https://dl.bintray.com/someuser/` into `~/bintray_backup`

```
./bin/download_bintray -u someuser -d ~/bintray_backup -c
```

The `-c` option will verify the size of the downloaded files.
This will slow down the process, but the results are cached so re-runs have no performance penalty.
By performing a file check you can safely recover from a corrupt download after a network interruption by simply re-running the program.

Once everything is downloaded you can prune all the cached files.
The caches make re-running the program a lot faster, but there is no reason to keep them if you have finished your backup.

```
./bin/download_bintray -d ~/bintray_backup -p
```

You now have a pristine mirror of your bintray artifacts!

## Contributing

1. Fork it (<https://github.com/your-github-user/download_bintray/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [da1nerd](https://github.com/da1nerd) - creator and maintainer
