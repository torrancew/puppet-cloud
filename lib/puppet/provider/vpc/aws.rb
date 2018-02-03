require_relative '../../../puppet_x/cloud/aws'

Puppet::Type.type(:vpc).provide(:aws) do
  include PuppetX::Cloud::AWS
  service :ec2

  def self.instances
    api_object = ec2('describe-vpcs')

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

  def create
    tags = []
    (resource[:metadata] || {}).merge({'Name': resource[:name]}).each do |k, v|
      tags << "Key=#{k},Value=#{v}"
    end

    vpc = ec2('create-vpc', 'cidr_block' => resource[:cidr])
    ec2('create-tags', 'resource' => vpc['Vpc']['VpcId'], 'tags' => tags.join(' '))
    @property_hash[:ensure] = :present
  end

  def destroy
    ec2('delete-vpc', 'vpc-id' => resource_id)
    @property_hash[:ensure] = :absent
  end

  def resource_id
    vpcs = ec2('describe-vpcs', 'filters' => "Name=tag:Name,Values=#{resource[:name]}")
    vpcs['Vpcs'].map{ |vpc| vpc['VpcId'] }.first
  end
end
