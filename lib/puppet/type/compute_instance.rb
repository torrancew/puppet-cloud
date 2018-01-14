Puppet::Type.newtype(:compute_instance) do
  @doc = 'Manage a cloud compute instance.'

  ensurable
  newparam(:name) do
    desc 'The name of the compute instance'
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
  end

  newproperty(:type) do
    desc 'The instance type'
  end

  newproperty(:virtualization) do
    desc 'The virtualization type'
  end

  newproperty(:vpc) do
    desc 'The name or ID of the VPC to deploy the instance to'
  end
end
