require 'binding_of_caller'
require 'yaml'
require 'pry-byebug'

class DynamicDebugger
  CONFIG_FILE_NAME = '.dynamic_debugger.config.yml'

  module DefaultConfigLoader
    def self.load
      return @@config if defined(@@config)

      config_file = "#{ENV['HOME']}/#{CONFIG_FILE_NAME}"
      raise "Missing configuration in: #{config_file}." unless File.exist?(config_file)

      @@config = YAML::load_file(config_file)
    end
  end

  class << self
    def debug(tag, &block)
      _binding = binding.of_caller(1)

      return block && yield unless breakpoint?(tag)

      pre_call_actions(tag, _binding)

      retval = block && yield
      return_call(tag, retval) if return_call?(tag)

      post_call_actions(tag, _binding)

      if return_override?(tag)
        return_override(tag)
      elsif return_code_override?(tag)
        return_code_override(tag, _binding)
      else
        retval
      end
    end

    def config_loader
      @@config_loader ||= DefaultConfigLoader
    end

    def set_config_loader(config_loader_instance)
      @@config_loader = config_loader_instance
    end

    private

    def config
      config_loader.load
    end

    def config_for_tag(tag)
      config.dig('breakpoints', tag.to_s)
    end

    def breakpoint?(tag)
      (cfg = config_for_tag(tag)) && (!cfg.key?('enabled') || cfg['enabled'])
    end

    def pre_call_actions(tag, _binding)
      call_actions(tag, _binding, 'pre_call')
    end

    def post_call_actions(tag, _binding)
      call_actions(tag, _binding, 'post_call')
    end

    def call_actions(tag, _binding, config_key)
      return unless cfg = config_for_tag(tag)[config_key]
      Array(cfg).each { |action| eval(action, _binding) }
    end

    def return_override?(tag)
      return unless cfg = config_for_tag(tag)
      cfg.key?('return') && cfg['return'].to_s.length > 0
    end

    def return_override(tag)
      try_numeric_cast(config_for_tag(tag).dig('return'))
    end

    def return_code_override?(tag)
      return unless cfg = config_for_tag(tag)
      cfg.key?('return_code') && cfg['return_code'].length > 0
    end

    def return_code_override(tag, _binding)
      eval(config_for_tag(tag).dig('return_code'), _binding)
    end

    def return_call?(tag)
      return unless cfg = config_for_tag(tag)
      cfg.key?('return_call')
    end

    def return_call(tag, retval)
      return unless cfg = config_for_tag(tag)['return_call']
      Array(cfg).each { |action| eval(action) }
    end

    def try_numeric_cast(raw)
      return raw unless raw.is_a?(String)
      begin
        return Integer(raw)
      rescue
        begin
          return Float(raw)
        rescue
          return raw
        end
      end
    end
  end
end
