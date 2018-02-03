require 'json'

module PuppetX
  module Cloud
    module AWS
      def self.included(base)
        base.send(:commands, :aws => 'aws')
        base.send(:mk_resource_methods)

        base.extend(ClassMethods)
        base.include(InstanceMethods)
      end

      module ClassMethods
        def awscli(svc, cmd, opts={})
          args = []
          opts.merge({'output' => 'json'}).each do |opt, val|
            args <<= "--#{opt}"
            args <<= val unless [true, false].include?(val)
          end
          return JSON.parse(aws(svc.to_s, cmd.to_s, *args.map(&:to_s)))
        end

        def service(svc)
          self.class.instance_eval do
            define_method(svc.to_sym) do |cmd, opts={}|
              awscli(svc, cmd, opts)
            end
          end

          self.instance_eval do
            define_method(svc.to_sym) do |cmd, opts={}|
              self.class.send(svc.to_sym, cmd, opts)
            end
          end
        end

        def tag(resource, metadata={})
          tags = metadata.keys.map{ |k| "Key=#{k},Value=#{metadata[k]}" }
          return awscli(:ec2, 'create-tags', 'resource' => resource, 'tags' => tags.join(' '))
        end

        def prefetch(resources)
          objs = instances
          resources.keys.each do |name|
            if provider = objs.find{ |obj| obj.name == name }
              resources[name].provider = provider
            end
          end
        end
      end

      module InstanceMethods
        def awscli(svc, cmd, opts={})
          self.class.awscli(svc, cmd, opts)
        end

        def tag(resource, metadata={})
          self.class.tag(resource, metadata)
        end

        def exists?
          @property_hash[:ensure] == :present
        end
      end
    end
  end
end
