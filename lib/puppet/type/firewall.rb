Puppet::Type.newtype(:firewall) do
  desc 'Manage a cloud firewall'

  ensurable
  newparam(:name, :namevar => true) do
    desc 'The name of the firewall'
  end

  newproperty(:description) do
    desc 'The firewall description'
    defaultto 'A Puppet-managed cloud firewall'
  end

  newproperty(:metadata) do
    desc 'The firewall metadata'
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
