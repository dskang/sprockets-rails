require 'sprockets'

module Sprockets
  module Rails
    class Environment < Sprockets::Environment
      def call(env)
        puts 'SRE call!'
        super(env)
      end
    end
  end
end
