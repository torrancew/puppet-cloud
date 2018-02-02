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
        def awscli(service, command, options={})
          args = []
          options.merge({'output' => 'json'}).each do |opt, val|
            args <<= "--#{opt}"
            args <<= val unless [true, false].include?(val)
          end
          return JSON.parse(aws(service.to_s, command.to_s, *args.map(&:to_s)))
        end

        def tag(resource, metadata={})
          tags = metadata.keys.map{ |k| "Key=#{k},Value=#{metadata[k]}" }
          return awscli('ec2', 'create-tags', 'resource' => resource, 'tags' => tags.join(' '))
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
        def awscli(service, command, options={})
          self.class.awscli(service, command, options)
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
