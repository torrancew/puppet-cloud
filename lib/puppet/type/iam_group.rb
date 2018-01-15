Puppet::Type.newtype(:iam_group) do
  desc 'Manage cloud IAM groups'

  ensurable
  newparam(:name, :namevar => true) do
    desc 'The name of the IAM group'
  end
end
