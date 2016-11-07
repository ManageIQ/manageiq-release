# ManageIQ release tools

[![Code Climate](https://codeclimate.com/github/ManageIQ/manageiq-release.svg)](https://codeclimate.com/github/ManageIQ/manageiq-release)

Tools for releasing new branches and tags of ManageIQ.

## Installation

```sh
git clone https://github.com/ManageIQ/manageiq-release.git`
bundle
```

## Usage

- Release a new tag

  ```sh
  bin/release_tag.rb --tag <new_tag_name> --branch <branch_name>
  ```

- Destroy a tag that was incorrectly created locally

  ```sh
  bin/destroy_tag.rb --tag <tag_name> --branch <branch_name>
  ```


## Development

Some things to note:

- The bin scripts are driven off of the `config/repos.yml` file.  This file
  lists the various branches and which repos make up a release for that branch.
- There is a `bin/console` script which is helpful for console-based testing.
  It will open an IRB session with the libraries files already required.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/manageiq-release.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
