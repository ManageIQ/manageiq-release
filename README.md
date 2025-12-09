# ManageIQ release tools


Tools for the ManageIQ project, including those for releasing new branches and tags.

## Installation

```sh
git clone https://github.com/ManageIQ/manageiq-release.git
```

## Usage

Scripts are provided in the `bin` directory to perform various tasks. Each one uses the [MultiRepo](https://github.com/ManageIQ/multi_repo) gem to perform the task on each repo listed in the `config/repos.yml` file.

See the [MultiRepo README](https://github.com/ManageIQ/multi_repo/#readme) file for more information on configuration.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ManageIQ/manageiq-release.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
