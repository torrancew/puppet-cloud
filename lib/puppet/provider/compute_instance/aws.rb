require 'fog'

Puppet::Type.type(:compute_instance).provide(:aws) do
  def self.connection
    @connection ||= Fog::Compute.new({:provider => 'AWS', :region => 'us-west-2'})
  end

  def self.find(filters)
    connection.servers.find(filters)
  end

  def self.instances
    connection.servers.collect do |server|
      new(
        :name           => server.tags['Name'] || server.id,
        :ensure         => (server.state.match(/terminat/) ? :absent : :present),
        :image          => server.image_id,
        :metadata       => server.tags.reject{ |key, _| key == 'Name' },
        :subnet         => server.subnet_id,
        :type           => server.flavor_id,
        :virtualization => server.virtualization_type,
        :vpc            => server.vpc_id,
      )
    end
  end

  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |n| n.name == name }
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def reload!
    server = self.class.connection.servers.find{ |s| s.tags['Name'] == resource[:name] }
    @property_hash[:name]           = server.tags['Name'] || server.id
    @property_hash[:ensure]         = (server.state.match(/terminat/) ? :absent : :present)
    @property_hash[:image]          = server.image_id
    @property_hash[:metadata]       = server.tags.reject{ |key, _| key == 'Name' }
    @property_hash[:subnet]         = server.subnet_id
    @property_hash[:type]           = server.flavor_id
    @property_hash[:virtualization] = server.virtualization_type
    @property_hash[:vpc]            = server.vpc_id
  end

  def create
    tags = (resource[:metadata] || {}).merge({'Name' => resource[:name]})
    server = self.class.connection.servers.create({
      :image_id            => resource[:image],
      :tags                => tags,
      :subnet_id           => resource[:subnet],
      :flavor_id           => resource[:type],
      :virtualization_type => resource[:virtualization],
      :vpc_id              => resource[:vpc],
    })
    server.wait_for{ ready? }
    reload!
  end

  def destroy
    server = self.class.connection.servers.find{ |s| s.tags['Name'] == resource[:name] }
    server.destroy
    reload!
  end
end
