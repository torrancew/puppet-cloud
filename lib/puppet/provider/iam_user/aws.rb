require 'json'

Puppet::Type.type(:iam_user).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'iam', 'list-users')
    api_object = JSON.parse(api_output)

    api_object['Users'].map do |user|
      new({
        :name   => user['UserName'],
        :ensure => :present,
      })
    end
  end

  def self.prefetch(resources)
    users = instances
    resources.keys.each do |name|
      if provider = users.find{ |u| u.name == name }
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    aws('--output', 'json', 'iam', 'create-user', '--user-name', resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    aws('--output', 'json', 'iam', 'delete-user', '--user-name', resource[:name])
    @property_hash[:ensure] = :absent
  end
end
