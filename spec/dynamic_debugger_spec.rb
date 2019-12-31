require 'rspec'
require_relative '../dynamic_debugger'

RSpec.describe(DynamicDebugger, 'Dynamic Debugger Basics') do
    before do
        DynamicDebugger.set_config_loader(FakeConfigLoader)
        @subject = ReactorSubject.new
    end

    describe('High level') do
        it('No config will do no change') do
            FakeConfigLoader.set_config({})
            @subject.fuel(100)
            expect(@subject.energy[:level]).to(eq(1.0))
        end

        it('Configuration can be disabled') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => false,
                        'return' => 0.5,
                    }
                }
            })

            @subject.fuel(100)
            expect(@subject.energy[:level]).to(eq(1.0))
        end
    end

    describe('Return override by value') do
        it('Return setting can override the return by value') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'return' => 0.5,
                    }
                }
            })

            @subject.fuel(100)
            expect(@subject.energy[:level]).to(eq(0.5))
        end

        it('Return setting can override the return by float string value') do
            [".5", "0.5", "5e-1"].each do |string_float_value|
                FakeConfigLoader.set_config({
                    'breakpoints' => {
                        'fuel' => {
                            'enabled' => true,
                            'return' => string_float_value,
                        }
                    }
                })

                @subject.fuel(100)
                expect(@subject.energy[:level]).to(eq(0.5))
            end
        end
    end

    describe('Return override by code') do
        it('Return setting can override the return by code') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'return_code' => "[0.2, 0.1].min",
                    }
                }
            })

            @subject.fuel(100)
            expect(@subject.energy[:level]).to(eq(0.1))
        end

        it('Has access to local variables') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'return_code' => "amount / (percentage_divider * 2.0)",
                    }
                }
            })

            @subject.fuel(80)
            expect(@subject.energy[:level]).to(eq(0.4))
        end
    end

    describe('Return inspection with code') do
        it('Return value can be inspected') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'return_call' => "InspectorFake.inspect(retval)",
                    }
                }
            })

            InspectorFake.reset
            @subject.fuel(100)
            expect(InspectorFake.history).to(eq([1.0]))
        end

        it('Return value can be inspected with mutliple calls') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'return_call' => [
                            "InspectorFake.inspect(retval)",
                            "InspectorFake.inspect(retval * 0.5)",
                        ],
                    }
                }
            })

            InspectorFake.reset
            @subject.fuel(100)
            expect(InspectorFake.history).to(eq([1.0, 0.5]))
        end
    end

    describe('Before execution calls') do
        it('Before execution can be inspected') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'pre_call' => "InspectorFake.inspect(self.class.name)",
                    }
                }
            })

            InspectorFake.reset
            @subject.fuel(100)
            expect(InspectorFake.history).to(eq(['ReactorSubject']))
        end
    end

    describe('After execution calls') do
        it('Before execution can be inspected') do
            FakeConfigLoader.set_config({
                'breakpoints' => {
                    'fuel' => {
                        'enabled' => true,
                        'post_call' => "InspectorFake.inspect(self.class.name)",
                    }
                }
            })

            InspectorFake.reset
            @subject.fuel(100)
            expect(InspectorFake.history).to(eq(['ReactorSubject']))
        end
    end
end

module FakeConfigLoader
    def self.set_config(config)
        @@config = config
    end

    def self.load
        @@config
    end
end

class ReactorSubject
    attr_reader :energy

    def initialize
        @energy = { level: 0.7 }
    end

    def drain
        @energy[:level] = 0.0
    end

    def fuel(amount)
        percentage_divider = 100.0
        percentage_amount = DynamicDebugger.debug(:fuel) { amount.to_f / percentage_divider }
        @energy[:level] = percentage_amount
    end
end

class InspectorFake
    class << self
        def reset
            @thing = []
        end

        def inspect(thing)
            @thing ||= []
            @thing << thing
        end

        def history
            @thing
        end
    end
end
