# ManageIQ release tools

[![Code Climate](https://codeclimate.com/github/ManageIQ/manageiq-release.svg)](https://codeclimate.com/github/ManageIQ/manageiq-release)

Tools for releasing new branches and tags of ManageIQ.

## Installation

```sh
git clone https://github.com/ManageIQ/manageiq-release.git
bundle
```

## Usage

- Release a new tag

  ```sh
  bin/release_tag.rb [--dry-run] --tag <new_tag_name> --branch <branch_name>
  ```

- Destroy a tag that was incorrectly created locally

  ```sh
  bin/destroy_tag.rb --tag <tag_name> --branch <branch_name>
  ```

- Update the Sprint milestones (see also [GitHub interactions](#github-interactions))

  ```sh
  bin/update_sprint_milestones.rb [--dry-run] --title <title>
  ```

## GitHub interactions

Certain commands interact with GitHub and expect a GitHub API Token set in the
ENV variable GITHUB_API_TOKEN.

If you don't already have a token, or want to create one specific to these
purposes
- Go to https://github.com/settings/tokens
- Choose "Generate New Token"
- Give the token a description
- At a mimimum, choose "repo" for the permissions.
- Click "Generate Token"
- Copy the token given to you, and keep it in a safe location, as once you leave
  the page, the token is no longer accessible

Then, in order to use is, export the ENV variable permanently, or pass it to the
program as part of the call.

  ```sh
  GITHUB_API_TOKEN=<token> bin/update_sprint_milestones.rb --title <title>
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
