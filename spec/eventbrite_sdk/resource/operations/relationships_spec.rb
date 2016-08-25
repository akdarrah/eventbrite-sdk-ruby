require 'spec_helper'

module EventbriteSDK
  class Resource
    module Operations
      RSpec.describe Relationships do
        describe '.belongs_to' do
          it 'defines a method that calls .retrieve on a matching class' do
            wheel = TestRelations::Wheel.new

            expect(wheel.car).to eq('id' => 'car_id')
          end
        end

        describe '.has_many' do
          it 'defines a method that returns a new list_class instance' do
            allow(TestRelations::List).to receive(:new).and_call_original
            car = TestRelations::Car.new

            result = car.wheels

            expect(result).to be_an_instance_of(car.list_class)

            expect(TestRelations::List).to have_received(:new).with(
              url_base:
                car.path(:wheels),
              object_class:
                EventbriteSDK::Resource::Operations::TestRelations::Wheel,
              key:
                'wheels'
            )
          end
        end

        private

        module TestRelations

          class Car
            include Relationships

            has_many :wheels, object_class: 'Wheel', key: 'wheels'

            def self.retrieve(value)
              value # Just pass through given value
            end

            def path(arg)
              arg
            end

            def resource_class_from_string(string)
              TestRelations.const_get(string)
            end

            def list_class
              List
            end
          end

          class Wheel
            include Relationships

            belongs_to :car, object_class: 'Car', mappings: { id: :car_id }

            def car_id
              'car_id'
            end

            def resource_class_from_string(string)
              TestRelations.const_get(string)
            end
          end

          class List
            attr_reader :args

            def initialize(args)
              @args = args
            end
          end
        end
      end
    end
  end
end
