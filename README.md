# download_bintray

JFrog is sunsetting Bintray on May 1, 2021 (see the [community announcement](https://jfrog.com/blog/into-the-sunset-bintray-jcenter-gocenter-and-chartcenter/)).
I couldn't find a simple way to backup all of my artifacts so I wrote this small client to download everything.

## Installation

```bash
shards build
```

This will compile and place the binary in `./bin`

## Usage

Run the executable with `--help` to get a list of options.
The following will download all of the artifacts of `someuser` from `https://dl.bintray.com/someuser/` into `~/bintray_backup`

```
./bin/download_bintray -u someuser -d ~/bintray_backup
```

## Contributing

1. Fork it (<https://github.com/your-github-user/download_bintray/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [da1nerd](https://github.com/da1nerd) - creator and maintainer
