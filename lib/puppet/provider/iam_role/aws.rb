require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:iam_role).provide(:aws) do
  include PuppetX::Cloud::AWS
  service :iam

  def self.instances
    api_object = iam('list-roles')

    api_object['Roles'].map do |role|
      new({
        :name   => role['RoleName'],
        :ensure => :present,
      })
    end
  end

  def create
    iam('create-role', 'role-name' => resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    iam('delete-role', 'role-name' => resource[:name])
    @property_hash[:ensure] = :absent
  end
end
