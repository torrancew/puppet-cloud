Puppet::Type.newtype(:subnet) do
  desc 'Manage a cloud subnet'

  ensurable
  newparam(:name, :namevar => true) do
    desc 'The name of the subnet'
  end

  newproperty(:cidr) do
    desc 'The CIDR block'
  end

  newproperty(:metadata) do
    desc 'The subnet metadata'
  end

  newproperty(:vpc) do
    desc 'The VPC ID'

    munge do |value|
      if v = Puppet::Type.type(:vpc).instances.find{ |i| i.name == value }
        v.provider.resource_id
      else
        value
      end
    end
  end

  autorequire(:vpc) do
    self[:vpc]
  end
end
