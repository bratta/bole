# frozen_string_literal: true

require 'sycl'
require 'stringio'

RSpec.describe Bole do
  let(:config_file) { File.join(__dir__, 'fixtures', 'bole.yml') }
  let(:string_out) { StringIO.new }

  it 'has a version number' do
    expect(Bole::VERSION).not_to be nil
  end

  describe 'with an invalid config file' do
    it 'raises an error when the supplied file does not exist' do
      expect { Bole::Manager.new(string_out, config: '/some/invalid/path.yml') }.to raise_error(Konfigyu::FileNotFoundException)
    end
  end

  describe 'with a valid config file' do
    let(:data) do
      Sycl::Hash.from_hash(
        'data' => { 'bole' => { 'level' => 'info' } }
      )
    end

    it 'instantiates the log manager' do
      expect { Bole::Manager.new(string_out, config: config_file) }.not_to raise_error
    end

    it 'creates a new config when not supplied one' do
      allow(Konfigyu::Config).to receive(:new).and_return(data)
      Bole::Manager.config = nil
      Bole::Manager.new(string_out, config: config_file)
      expect(Konfigyu::Config).to have_received(:new)
      Bole::Manager.config = nil
    end

    it 'uses a supplied config instead of instantiating a new one' do
      allow(Konfigyu::Config).to receive(:new).and_return(data)
      Bole::Manager.config = data
      Bole::Manager.new(string_out, config: config_file)
      expect(Konfigyu::Config).not_to have_received(:new)
      Bole::Manager.config = nil
    end
  end

  describe 'initializing the log device' do
    it 'calls logdev to update the device if a file is specified' do
      bole = Bole::Manager.new(string_out, config: config_file)
      Bole::Manager.config.data.bole.file = string_out
      allow(bole).to receive(:logger=).with(string_out)
      bole.send(:initialize_log_device)
      expect(bole).to have_received(:logger=).with(string_out)
    end
  end

  describe 'initializing the formatter' do
    it 'uses a standard format' do
      bole = Bole::Manager.new(string_out, config: config_file)
      allow(bole).to receive(:get_custom_formatter)
      bole.send(:initialize_formatter)
      expect(bole).not_to have_received(:get_custom_formatter)
    end

    it 'uses a custom formatter when provided one' do
      bole = Bole::Manager.new(string_out, config: config_file)
      Bole::Manager.config.data.bole.format = 'custom format'
      allow(bole).to receive(:get_custom_formatter)
      bole.send(:initialize_formatter)
      expect(bole).to have_received(:get_custom_formatter).with('custom format')
      Bole::Manager.config.data.bole.format = nil
    end
  end

  describe 'initializing the program name' do
    let(:bole) { Bole::Manager.new(string_out, config: config_file) }

    it 'uses the default if no name is specified' do
      Bole::Manager.config.data.bole.progname = nil
      bole.send(:initialize_progname)
      expect(bole.progname).to eq('Bole')
    end

    it 'uses the program name in the config if specified' do
      Bole::Manager.config.data.bole.progname = 'rspec'
      bole.send(:initialize_progname)
      expect(bole.progname).to eq('rspec')
    end

    it 'prefers the program name passed on the constructor' do
      bole = Bole::Manager.new(string_out, progname: 'rspec method', config: config_file)
      expect(bole.progname).to eq('rspec method')
    end
  end

  describe 'initializing the log level' do
    let(:bole) { Bole::Manager.new(string_out, config: config_file) }

    it 'disables logging if the log level is none' do
      Bole::Manager.config.data.bole.level = :none
      bole.send(:initialize_log_level)
      expect(bole.enabled).to be_falsey
    end

    it 'enables logging if the log level is anything else' do
      Bole::Manager.config.data.bole.level = :info
      bole.send(:initialize_log_level)
      expect(bole.enabled).to be_truthy
    end

    it 'sets the log level appropriately' do
      Bole::Manager.config.data.bole.level = :info
      bole.send(:initialize_log_level)
      expect(bole.level).to eq(Logger::INFO)
    end
  end

  describe 'logging' do
    let(:bole) { Bole::Manager.new(string_out, config: config_file) }

    describe 'logger' do
      it 'provides access to the logdev instance variable' do
        expect(bole.logger).not_to be_nil
      end

      it 'sets the log device when a new logger is set' do
        allow(Logger::LogDevice).to receive(:new).and_call_original
        allow(Logger::LogDevice).to receive(:new).with('/tmp/somefile.log', any_args)
        bole.logger = '/tmp/somefile.log'
        expect(Logger::LogDevice).to have_received(:new).with('/tmp/somefile.log', any_args)
      end
    end

    describe 'level' do
      let(:bole) { Bole::Manager.new(string_out, config: config_file) }

      it 'overloads the default to allow "none"' do
        expect { bole.level = :none }.not_to raise_error
      end

      it 'sets the logging level to unknown on "none"' do
        bole.level = :none
        expect(bole.level).to eq(Logger::UNKNOWN)
      end

      it 'disabled logging when set to "none"' do
        bole.level = :none
        expect(bole.enabled).to be_falsy
      end
    end

    it 'does nothing if the log is disabled' do
      bole.enabled = false
      bole.info('foo')
      string_out.rewind
      expect(string_out.read).not_to include('foo')
    end

    it 'outputs the log message to the log file' do
      bole.logger = string_out
      bole.info('foo')
      string_out.rewind
      expect(string_out.read).to include('foo')
    end
  end

  describe 'private methods' do
    let(:bole) { Bole::Manager.new(string_out, config: config_file) }

    describe '#parse_custom_formatter' do
      it 'parses the severity flag' do
        expect(bole.send(:parse_custom_formatter, '-{severity}-', 'info', nil, nil, nil)).to eq('-info-')
      end

      it 'parses the datetime flag' do
        expect(bole.send(:parse_custom_formatter, '-{datetime}-', nil, 'today', nil, nil)).to eq('-today-')
      end

      it 'parses the progname flag' do
        expect(bole.send(:parse_custom_formatter, '-{progname}-', nil, nil, 'command.com', nil)).to eq('-command.com-')
      end

      it 'parses the msg flag' do
        expect(bole.send(:parse_custom_formatter, '-{msg}-', nil, nil, nil, 'oh hai')).to eq('-oh hai-')
      end

      it 'handles all flags' do
        format = '[{datetime} :: {progname} ({severity})] {msg}'
        expected = '[2018-10-02 :: bole (info)] oh hai'
        expect(bole.send(:parse_custom_formatter, format, 'info', '2018-10-02', 'bole', 'oh hai')).to eq(expected)
      end

      it 'handles no flags' do
        format = 'foo bar'
        expect(bole.send(:parse_custom_formatter, format, 'info', '2018-10-02', 'bole', 'oh hai')).to eq(format)
      end
    end
  end
end
