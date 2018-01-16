require 'json'

Puppet::Type.type(:subnet).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'ec2', 'describe-subnets')
    api_object = JSON.parse(api_output)

    api_object['Subnets'].map do |subnet|
      tags = {}
      (subnet['Tags'] || {}).each do |t|
        tags[t['Key']] = t['Value']
      end

      new({
        :name     => (tags['Name'] || subnet['VpcId']),
        :ensure   => (subnet['State'] == 'terminated' ? :absent : :present),
        :cidr     => subnet['CidrBlock'],
        :metadata => tags.reject{ |k, _| k == 'Name' },
        :vpc      => subnet['VpcId'],
      })
    end
  end

  def self.prefetch(resources)
    subnets = instances
    resources.keys.each do |name|
      if provider = subnets.find{ |subnet| subnet.name == name }
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    tags = []
    (resource[:metadata] || {}).merge({'Name': resource[:name]}).each do |k, v|
      tags << "Key=#{k},Value=#{v}"
    end

    args   = []
    args <<= '--dry-run' if resource[:noop]
    api_output = aws('--output', 'json', 'ec2', 'create-subnet', '--cidr-block', resource[:cidr], '--vpc-id', resource[:vpc], *args)
    subnet     = JSON.parse(api_output)
    aws('--output', 'json', 'ec2', 'create-tags', '--resource', subnet['Subnet']['SubnetId'], '--tags', tags.join(' '), *args)
    @property_hash[:ensure] = :present
  end

  def destroy
    args   = []
    args <<= '--dry-run' if resource[:noop]
    aws('--output', 'json', 'ec2', 'delete-subnet', '--subnet-id', resource_id, *args)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    api_output = aws('--output', 'json', 'ec2', 'describe-subnets', '--filters', "Name=tag:Name,Values=#{resource[:name]}")
    subnets    = JSON.parse(api_output)
    subnets['Subnets'].map{ |subnet| subnet['SubnetId'] }.first
  end
end
