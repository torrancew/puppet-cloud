Puppet::Type.newtype(:server) do
  @doc = 'Manage a cloud server.'

  ensurable
  newparam(:name) do
    desc 'The name of the server'
  end

  newproperty(:firewalls, :array_matching => :all) do
    desc 'The firewall ID'

    munge do |values|
      values.map do |value|
        if firewall = Puppet::Type.type(:firewall).instances.find{ |i| i.name == value }
          firewall.provider.resource_id
        else
          value
        end
      end
    end
  end

  newproperty(:image) do
    desc 'The name or ID of the image to boot with'
  end

  newproperty(:metadata) do
    desc 'The server metadata'

    def is_to_s(value)
      value.inspect
    end

    def should_to_s(value)
      value.inspect
    end
  end

  newproperty(:subnet) do
    desc 'The subnet ID'

    munge do |value|
      if subnet = Puppet::Type.type(:subnet).instances.find{ |i| i.name == value }
        subnet.provider.resource_id
      else
        value
      end
    end
  end

  newproperty(:type) do
    desc 'The server type'
  end

  newproperty(:virtualization) do
    desc 'The virtualization type'
  end

  newproperty(:vpc) do
    desc 'The name or ID of the VPC to deploy the server to'

    munge do |value|
      if vpc = Puppet::Type.type(:vpc).instances.find{ |i| i.name == value }
        vpc.provider.resource_id
      else
        value
      end
    end
  end

  newparam(:user_data) do
    desc 'The user data to boot with'
    defaultto :undef
  end

  autorequire(:firewall) do
    self[:firewalls]
  end

  autorequire(:subnet) do
    self[:subnet]
  end

  autorequire(:vpc) do
    self[:vpc]
  end
end
