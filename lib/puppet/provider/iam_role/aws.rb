require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:iam_role).provide(:aws) do
  include PuppetX::Cloud::AWS

  def self.instances
    api_object = awscli('iam', 'list-roles')

    api_object['Roles'].map do |role|
      new({
        :name   => role['RoleName'],
        :ensure => :present,
      })
    end
  end

  def create
    awscli('iam', 'create-role', 'role-name' => resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    awscli('iam', 'delete-role', 'role-name' => resource[:name])
    @property_hash[:ensure] = :absent
  end
end
