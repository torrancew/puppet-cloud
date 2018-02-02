require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:firewall).provide(:aws) do
  include PuppetX::Cloud::AWS

  def self.instances
    api_object = awscli('ec2', 'describe-security-groups')

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

  def create
    tags = []
    (resource[:metadata] || {}).merge({'Name': resource[:name]}).each do |k, v|
      tags << "Key=#{k},Value=#{v}"
    end

    firewall = awscli('ec2', 'create-security-group', 'vpc-id' => resource[:vpc], 'group-name' => resource[:name], 'description' => resource[:description])
    awscli('ec2', 'create-tags', 'resource', firewall['GroupId'], 'tags', tags.join(' '))
    @property_hash[:ensure] = :present
  end

  def destroy
    awscli('ec2', 'delete-security-group', 'group-id' => resource_id)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    firewalls = awscli('ec2', 'describe-security-groups', '--filters', "Name=tag:Name,Values=#{resource[:name]}")
    firewalls['SecurityGroups'].map{ |firewall| firewall['GroupId'] }.first
  end
end
