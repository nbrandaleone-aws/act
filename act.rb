require 'aws-sdk-appmesh'   # v3
require 'rainbow'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: act.rb [options]. Gives information regarding App Mesh constructs."
  opts.on("-v", "--verbose", "Show extra information")
  opts.on("-r <region>","--region <region>", "AWS region", String)
  opts.on("-m <mesh_name>","--mesh <mesh_name>", "App Mesh name", String)
end.parse!(into: options)

class Tree
  attr_accessor :children, :value, :type

  def initialize(v)
    @value = v
    @type = ""
    @children = []
  end
end

###############################################################

def add_virtual_services(client, root)
  resp = client.list_virtual_services({mesh_name: root.value })

  # Add Virtual Services
  resp.virtual_services.each do | vs |
    node = Tree.new("#{vs.virtual_service_name}")
    node.type = "VirtualService"
    root.children << node
  end

  # Add Virtual Nodes or Routers
  root.children.each do | vs |
    resp = client.describe_virtual_service({mesh_name: root.value, 
                                            virtual_service_name: vs.value })
    if resp.virtual_service.spec.provider.virtual_node != nil
      node = Tree.new("#{resp.virtual_service.spec.provider.virtual_node.virtual_node_name}")
      node.type = "VirtualNode"
      node.children << add_vn_spec(client, node)
      vs.children << node
    elsif resp.virtual_service.spec.provider.virtual_router != nil
      node = Tree.new("#{resp.virtual_service.spec.provider.virtual_router}")
      node.type = "VirtualRouter"
      vs.children << node
    end # End else
  end   # Node or Router
end

# Add Virtual Node Spec. We are only grabbing the first listener right now. Simplicity.
def add_vn_spec(client, node)
  resp = client.describe_virtual_node({mesh_name: $root.value, virtual_node_name: node.value })

  # Add Virtual Node Spec
  n = Tree.new("#{resp.virtual_node.spec.listeners[0].port_mapping}")
  n.type = "PortMapping"
  if resp.virtual_node.spec.backends.length > 0
    n.children << add_vn_backend(client, node)
  end
  return n
end   # End Virtual Node spec for VS

# Add Backends
def add_vn_backend(client, node)
  resp = client.describe_virtual_node({mesh_name: $root.value, virtual_node_name: node.value })

  backend_list = []
  resp.virtual_node.spec.backends.each do | backend |
    backend_list << "#{backend.virtual_service.virtual_service_name}"
  end
  n = Tree.new(backend_list)
  n.type = "Backend"
  return n
end  # End Backend

def recurse(location, prefix = '')
  nodes = location.children
  last_idx = nodes.length - 1

  nodes.each_with_index do | node, idx |
    pointer, preadd = (idx == last_idx) ? ['└── ', '    '] : ['├── ', '│   ']
    print "#{prefix}#{pointer}#{node.type}/" 
    case node.type
    when "PortMapping"
      puts Rainbow("#{node.value}").blue.bright
    when "Backend"
      puts Rainbow("#{node.value}").yellow.bright
    else 
      puts Rainbow("#{node.value}").bright
    end
    recurse(node, "#{prefix}#{preadd}") if node.children.any?
  end
end

def print_root(my_tree)
  print Rainbow("Mesh").green + "\t\t\t\t"
  puts "Components/" ++ Rainbow("Name").bright
  print "#{my_tree.type}/" 
  puts Rainbow("#{my_tree.value}").bright
end

##################################################################
## The program is made up of 3 stages.
#  1) Get the data via AWS API
#  2) Put the data into a tree data structure
#  3) Print out the data recursively in a pretty format
##
##################################################################

### Connect to appropriate region, or us-west-2 if not set.
# TODO Probably should default to credential default region if not set
if options.key?(:region)
  client = Aws::AppMesh::Client.new(region: options[:region])
else
  client = Aws::AppMesh::Client.new(region: 'us-west-2')
end

### Grab first mesh in desired region.
# FIXME Perhaps print out all meshes, instead of just grabbing info from first?
if options.key?(:mesh)
  t = Tree.new("#{options[:mesh]}")
else
  resp = client.list_meshes({ limit: 1 })
  t = Tree.new(resp.meshes[0].mesh_name)
end

t.type = "mesh"
$root = t  # FIXME This may not be necessary. Just nice to have global reference to root

add_virtual_services(client, t)
print_root(t)
recurse(t)

# FIXME Add verbose option (or remove option)
#### End of Program
