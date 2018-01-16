Puppet::Type.newtype(:compute_instance) do
  @doc = 'Manage a cloud compute instance.'

  ensurable
  newparam(:name) do
    desc 'The name of the compute instance'
  end

  newproperty(:firewall) do
    desc 'The firewall ID'

    munge do |value|
      if firewall = Puppet::Type.type(:firewall).instances.find{ |i| i.name == value }
        firewall.provider.resource_id
      else
        value
      end
    end
  end

  newproperty(:image) do
    desc 'The name or ID of the image to boot with'
  end

  newproperty(:metadata) do
    desc 'The instance metadata'

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
    desc 'The instance type'
  end

  newproperty(:virtualization) do
    desc 'The virtualization type'
  end

  newproperty(:vpc) do
    desc 'The name or ID of the VPC to deploy the instance to'

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

  autorequire(:subnet) do
    self[:subnet]
  end

  autorequire(:vpc) do
    self[:vpc]
  end
end
