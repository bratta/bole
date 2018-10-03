# Bole

![CircleCI branch](https://img.shields.io/circleci/project/github/bratta/bole/master.svg)
![GitHub](https://img.shields.io/github/license/bratta/bole.svg)
![GitHub issues](https://img.shields.io/github/issues/bratta/bole.svg)
![Gem](https://img.shields.io/gem/v/bole.svg)

The Ruby Logger, part of the standard library, is a pretty decent logging tool but isn't as easy to use or as configurable as I would like it to be. This gem wraps Logger with some extra love to allow it to load configuration values from a YAML file via the [Konfigyu](https://github.com/bratta/konfigyu) gem as well as giving it the ability to be enabled/disabled via a flag or by setting the logging level to `:none`.

This gem also makes it easier to swap logging devices on the fly, so you can switch between log files, StringIO instances, or STDOUT, etc. without creating a new intance of the object.

The Konfigyu data can be loaded from the YAML file when a Bole instance is created, or you can set it on the class if you have an existing config used by the rest of your application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bole'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bole

## Usage

The most basic usage is the exact same as the [Ruby Logger](https://ruby-doc.org/stdlib-2.5.1/libdoc/logger/rdoc/Logger.html) class.

It gets more interesting when you set up a config file and pass that to the class. For example, you can create a configuration file that looks like this and save it as `bole.yml`:

```yaml
bole:
  file: /tmp/bole.log
  level: info
  progname: Bole
  format: "[ {datetime} :: {severity} from {progname} ] {msg}"
```

Then, in your code, you can instantiate the Bole logger like this:

```ruby
require 'bole'
bole = Bole::Manager.new(STDOUT, config: 'bole.yml')

bole.info('This is a test log message')
```

Then if you look at `/tmp/bole.log` you should see:

```
# Logfile created on 2018-10-03 14:19:01 -0500 by logger.rb/61378
[ 2018-10-03 14:22:02 -0500 :: INFO from Bole ] This is a test log message
```

## Switching the logger

You can use `bole.logger` to change the logging device on the fly:

```ruby
require 'bole'
require 'stringio'

bole = Bole::Manager.new(STDOUT)
bole.info('This goes to STDOUT')

string_out = StringIO.new
bole.logger = string_out
bole.info('This goes to StringIO')
string_out.rewind
puts string_out.read
```

## Configuration File Format

The format of the configuration file looks like this:

```yaml
bole:
  # (optional) If not specified, logging will go to whatever
  # is passed to the constructor of the object, or STDOUT barring
  # that. If you wish to use a File object, STDERR, or something
  # like StringIO, then omit this value and pass it in the 
  # constructor, or set @logger (which this class exposes).
  file: /var/log/bole.log

  # (required) One of: none, fatal, error, warn, info, or debug
  level: info

  # (optional) The reporting program name. Defaults to 'Bole'
  progname: Bole

  # (optional) will default to Ruby's default Logger formatter
  # This is a string with these variables replaced. If you
  # wish to override the datetime format, you can always set the
  # value in code, e.g.:
  #
  #     bole = Bole::Manager.new(config_file)
  #     bole.datetime_format = '%Y-%m-%d %H:%M:%S'
  format: "[ {datetime} :: {severity} from {progname} ] {msg}"
```

### bole.file

In the configuration file, if you specify a file for Bole to use for logging, it will use that instead of whatever is passed to the constructor.  Note that currently this is a bit awkward as the config file is read AFTER the base logger is instantiated, so you end up with a default logger (STDOUT or whatever you pass as the first argument to the initializer), then it is switched over to whatever you specify in the file. Future versions may fix this.

You can't use an open File object, StringIO, or STDOUT/STDERR in this case.  You will only be able to pass a file name via the configuration file. If you want to use something more advanced, do it when you create the logger or by using `bole.logger = STDOUT` to set the logging device.

### bole.level

These correspond to the logging levels in the default Ruby Logger class, but we also add the "none" level, which is one way to disable logging either temporarily or permenantly. You can also pause logging in code by setting `bole.enabled = false` and then `bole.enabled = true` to re-enable logging.

### bole.progname

This is the name of the program as displayed in the log message.

### bole.format

If you wish to override the format, you can specify a string here with some template variables.

* **{datetime}** = The datetime
* **{severity}** = The logging level (i.e. INFO, DEBUG, etc.)
* **{progname}** = The program name
* **{msg}** =  The log message itself

An example would be this string:

```yaml
bole:
  level: info
  format: "-=# {datetime} -- Message from {progname} ({severity}) :: {msg} #=-"
```

Resulting in:

```
-=# 2018-10-03 14:22:02 -0500 -- Message from Bole (INFO) :: This is a test log message #=-
```

Note that none of the fields are required, so omit ones you don't need. In the future filtering and transorming might be possible. For now, though, if you need something complex like formatting the timestamp to something custom, you can use the regular facilities from the Ruby Logger class to make your changes.

## Configuration Sharing

Let's say you have an application that already has a Konfigyu YAML loaded and you want to add a section for Bole and use it. It's easy to share config by setting it on the class before instantiating it, and it will use that config:

```ruby
# Config exists in 'config'
config = Konfigyu::Config.new('application.yml')

Bole::Manager.config = config
bole = Bole::Manager.new
bole.info('Done!')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bratta/bole. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bole project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bratta/bole/blob/master/CODE_OF_CONDUCT.md).
