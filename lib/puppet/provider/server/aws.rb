require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:server).provide(:aws) do
  include PuppetX::Cloud::AWS
  service :ec2

  def self.instances
    api_object = ec2('describe-instances')

    api_object['Reservations'].map do |r|
      r['Instances'].map do |i|

        tags = Hash.new
        (i['Tags']||[]).each do |t|
          tags[t['Key']] = t['Value']
        end

        new({
          :name           => (tags['Name'] || i['InstanceId']),
          :ensure         => (i['State']['Name'].match(/terminat/) ? :absent : :present),
          :firewall       => i['SecurityGroups'].map{ |g| g['GroupName'] }.first,
          :image          => i['ImageId'],
          :metadata       => tags.reject{ |k, _| k == 'Name' },
          :subnet         => i['NetworkInterfaces'].map{ |iface| iface['SubnetId'] }.first,
          :type           => i['InstanceType'],
          :virtualization => i['VirtualizationType'],
          :vpc            => i['VpcId'],
        })
      end
    end.flatten
  end

  def create
    tags = []
    (resource[:metadata] || {}).merge({'Name': resource[:name]}).each do |k, v|
      tags <<= "{Key=#{k},Value=#{v}}"
    end

    opts = {
      'image-id'           => resource[:image],
      'instance-type'      => resource[:type],
      'security-group-ids' => resource[:firewall],
      'subnet-id'          => resource[:subnet],
      'tag-specifications' => "ResourceType=instance,Tags=[#{tags.join(',')}]",
    }
    opts['user-data'] = resource[:user_data] if resource[:user_data]

    ec2('run-instances', opts)
    @property_hash[:ensure] = :present
  end

  def destroy
    ec2('terminate-instances', 'instance-ids' => resource_id)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    nodes = ec2('describe-instances', 'filters' => "Name=tag:Name,Values=#{resource[:name]}")
    nodes['Reservations'].map{ |r| r['Instances'].map{ |i| i['InstanceId'] } }.flatten.first
  end
end
