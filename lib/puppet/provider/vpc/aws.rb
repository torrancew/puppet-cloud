require 'json'

Puppet::Type.type(:vpc).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'ec2', 'describe-vpcs')
    api_object = JSON.parse(api_output)

    api_object['Vpcs'].map do |vpc|
      tags = {}
      (vpc['Tags'] || {}).each do |t|
        tags[t['Key']] = t['Value']
      end

      new({
        :name     => (tags['Name'] || vpc['VpcId']),
        :ensure   => (vpc['State'] == 'terminated' ? :absent : :present),
        :cidr     => vpc['CidrBlockAssociationSet'].map{ |a| a['CidrBlock'] }.first,
        :metadata => tags.reject{ |k, _| k == 'Name' },
      })
    end
  end

  def self.prefetch(resources)
    vpcs = instances
    resources.keys.each do |name|
      if provider = vpcs.find{ |vpc| vpc.name == name }
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
    api_output = aws('--output', 'json', 'ec2', 'create-vpc', '--cidr-block', resource[:cidr], *args)
    vpc        = JSON.parse(api_output)
    aws('--output', 'json', 'ec2', 'create-tags', '--resource', vpc['Vpc']['VpcId'], '--tags', tags.join(' '), *args)
    @property_hash[:ensure] = :present
  end

  def destroy
    args   = []
    args <<= '--dry-run' if resource[:noop]
    aws('--output', 'json', 'ec2', 'delete-vpc', '--vpc-id', resource_id, *args)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    api_output = aws('--output', 'json', 'ec2', 'describe-vpcs', '--filters', "Name=tag:Name,Values=#{resource[:name]}")
    vpcs        = JSON.parse(api_output)
    vpcs['Vpcs'].map{ |vpc| vpc['VpcId'] }.first
  end
end
