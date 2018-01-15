require 'json'

Puppet::Type.type(:iam_group).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'iam', 'list-groups')
    api_object = JSON.parse(api_output)

    api_object['Groups'].map do |group|
      new({
        :name   => group['GroupName'],
        :ensure => :present,
      })
    end
  end

  def self.prefetch(resources)
    groups = instances
    resources.keys.each do |name|
      if provider = groups.find{ |g| g.name == name }
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    aws('--output', 'json', 'iam', 'create-group', '--group-name', resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    aws('--output', 'json', 'iam', 'delete-group', '--group-name', resource[:name])
    @property_hash[:ensure] = :absent
  end
end
