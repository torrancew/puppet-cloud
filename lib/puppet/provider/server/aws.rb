require 'json'

Puppet::Type.type(:server).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'ec2', 'describe-instances')
    api_object = JSON.parse(api_output)

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

  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |n| n.name == name }
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
      tags <<= "{Key=#{k},Value=#{v}}"
    end

    opts = {
      '--image-id'           => resource[:image],
      '--instance-type'      => resource[:type],
      '--security-group-ids' => resource[:firewall],
      '--subnet-id'          => resource[:subnet],
      '--tag-specifications' => "ResourceType=instance,Tags=[#{tags.join(',')}]",
    }
    opts['--user-data'] = resource[:user_data] if resource[:user_data]

    args   = []
    opts.each do |key, value|
      args <<= key
      args <<= value
    end
    args <<= '--dry-run' if resource[:noop]

    aws('--output', 'json', 'ec2', 'run-instances', *args)
    @property_hash[:ensure] = :present
  end

  def destroy
    args   = []
    args <<= '--dry-run' if resource[:noop]
    aws('--output', 'json', 'ec2', 'terminate-instances', '--instance-ids', resource_id, *args)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    api_output = aws('--output', 'json', 'ec2', 'describe-instances', '--filters', "Name=tag:Name,Values=#{resource[:name]}")
    nodes = JSON.parse(api_output)
    nodes['Reservations'].map{ |r| r['Instances'].map{ |i| i['InstanceId'] } }.flatten.first
  end
end
