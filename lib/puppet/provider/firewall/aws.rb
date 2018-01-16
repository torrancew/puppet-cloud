require 'json'

Puppet::Type.type(:firewall).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'ec2', 'describe-security-groups')
    api_object = JSON.parse(api_output)

    api_object['SecurityGroups'].map do |firewall|
      tags = {}
      (firewall['Tags'] || {}).each do |t|
        tags[t['Key']] = t['Value']
      end

      new({
        :name        => firewall['GroupName'],
        :ensure      => :present,
        :description => firewall['Description'],
        :metadata    => tags.reject{ |k, _| k == 'Name' },
        :vpc         => firewall['VpcId'],
      })
    end
  end

  def self.prefetch(resources)
    firewalls = instances
    resources.keys.each do |name|
      if provider = firewalls.find{ |firewall| firewall.name == name }
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
    api_output = aws('--output', 'json', 'ec2', 'create-security-group', '--vpc-id', resource[:vpc], '--group-name', resource[:name], '--description', resource[:description], *args)
    firewall     = JSON.parse(api_output)
    aws('--output', 'json', 'ec2', 'create-tags', '--resource', firewall['GroupId'], '--tags', tags.join(' '), *args)
    @property_hash[:ensure] = :present
  end

  def destroy
    args   = []
    args <<= '--dry-run' if resource[:noop]
    aws('--output', 'json', 'ec2', 'delete-security-group', '--group-id', resource_id, *args)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    api_output = aws('--output', 'json', 'ec2', 'describe-security-groups', '--filters', "Name=tag:Name,Values=#{resource[:name]}")
    firewalls    = JSON.parse(api_output)
    firewalls['SecurityGroups'].map{ |firewall| firewall['GroupId'] }.first
  end
end
