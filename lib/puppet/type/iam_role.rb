Puppet::Type.newtype(:iam_role) do
  desc 'Manage cloud IAM roles'

  ensurable
  newparam(:name, :namevar => true) do
    desc 'The name of the IAM role'
  end
end
