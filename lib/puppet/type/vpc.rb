Puppet::Type.newtype(:vpc) do
  desc 'Manage a Virtual Private Cloud'

  ensurable
  newparam(:name, :namevar => true) do
    desc 'The name of the VPC'
  end

  newproperty(:cidr) do
    desc 'The CIDR to use for the VPC'
  end

  newproperty(:metadata) do
    desc 'The metadata to set for the VPC'
  end
end
