require 'json'

Puppet::Type.type(:iam_role).provide(:aws) do
  commands :aws => 'aws'

  def self.instances
    api_output = aws('--output', 'json', 'iam', 'list-roles')
    api_object = JSON.parse(api_output)

    api_object['Roles'].map do |role|
      new({
        :name   => role['RoleName'],
        :ensure => :present,
      })
    end
  end

  def self.prefetch(resources)
    roles = instances
    resources.keys.each do |name|
      if provider = roles.find{ |r| r.name == name }
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    aws('--output', 'json', 'iam', 'create-role', '--role-name', resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    aws('--output', 'json', 'iam', 'delete-role', '--role-name', resource[:name])
    @property_hash[:ensure] = :absent
  end
end
