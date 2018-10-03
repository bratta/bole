# frozen_string_literal: true

module Bole
  # Logger main class
  class Manager < Logger
    attr_accessor :enabled

    PROGNAME = 'Bole'
    LOG_LEVELS = {
      none: Logger::UNKNOWN,
      fatal: Logger::FATAL,
      error: Logger::ERROR,
      warn: Logger::WARN,
      info: Logger::INFO,
      debug: Logger::DEBUG
    }.freeze

    # Class level accessibility for config
    class << self
      attr_accessor :config
    end

    # Initializer arguments:
    # The first set of arguments are the exact same as the Ruby
    # Standard Library's logger class. The goal of this class is to
    # extend the functionality to make the class easier to work with
    # so we are adding an extra argument to take an additional option:
    #
    # config: '/path/to/bole.yml'
    #
    # This is an optional argument that is the path to the Konfigyu
    # config YAML file so defaults can easily be persisted as part of
    # your application's configuration. Optionally you can specify an
    # existing Konfigyu object in Bole::Manager.config
    def initialize(logdev = STDOUT, shift_age = 0, shift_size = 1_048_576,
                   level: LOG_LEVELS[:debug], progname: nil, formatter: nil,
                   datetime_format: nil, shift_period_suffix: '%Y%m%d',
                   config: nil)
      initialize_configuration(config)

      @shift_age = shift_age
      @shift_size = shift_size
      @shift_period_suffix = '%Y%m%d'

      super(logdev, shift_age, shift_size,
            level: level, progname: progname, formatter: formatter,
            datetime_format: datetime_format,
            shift_period_suffix: shift_period_suffix)
      initialize_logger
    end

    def logger
      @logdev
    end

    def logger=(new_logdev)
      @logdev = Logger::LogDevice.new(
        new_logdev,
        shift_age: @shift_age,
        shift_size: @shift_size,
        shift_period_suffix: @shift_period_suffix
      )
    end

    def level=(severity)
      if severity.to_s.casecmp('none').zero?
        @level = Logger::UNKNOWN
        @enabled = false
      else
        @enabled = true
        super(severity)
      end
    end

    def add(severity, message = nil, progname = nil)
      super(severity, message, progname) if @enabled
    end

    private

    def config_requirements
      {
        required_fields: ['bole', 'bole.level'],
        required_values: {
          'bole.level': LOG_LEVELS.keys.map(&:to_s)
        }
      }
    end

    def initialize_configuration(config_file = nil)
      return unless Bole::Manager.config.nil?

      Bole::Manager.config =
        if config_file
          Konfigyu::Config.new(config_file, config_requirements)
        else
          Sycl::Hash.from_hash(
            'data' => { 'bole' => { 'level' => LOG_LEVELS.key(@level) } }
          )
        end
    end

    def initialize_logger
      initialize_log_device
      initialize_progname
      initialize_formatter
      initialize_log_level
    end

    def initialize_log_device
      self.logger = Bole::Manager.config.data.bole.file if Bole::Manager.config.data.bole.file
    end

    def initialize_progname
      @progname = Bole::Manager.config.data.bole.progname || PROGNAME if progname.nil?
    end

    def initialize_formatter
      @formatter = get_custom_formatter(Bole::Manager.config.data.bole.format) if Bole::Manager.config.data.bole.format
    end

    def initialize_log_level
      @enabled = Bole::Manager.config.data.bole.level != :none
      @level = LOG_LEVELS[Bole::Manager.config.data.bole.level&.to_sym] || Logger::DEBUG
    end

    def get_custom_formatter(custom_format)
      proc do |severity, datetime, progname, msg|
        parse_custom_formatter(custom_format, severity, datetime, progname, msg)
      end
    end

    def parse_custom_formatter(format, severity, datetime, progname, msg)
      format.gsub('{severity}', severity || '')
            .gsub('{datetime}', datetime.to_s || '')
            .gsub('{progname}', progname || '')
            .gsub('{msg}', msg || '')
    end
  end
end
