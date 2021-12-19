summary: Getting Started with Ansible
id: getting-started-ansible
status: Published 
authors: Ansible
feedback link: https://fteychene.github.io/cloud-101-course/

# Getting started with Ansible

## Ansible

Ansible is an IT automation tool. It can configure systems, deploy software, and orchestrate more advanced IT tasks such as continuous deployments or zero downtime rolling updates.

Ansible’s main goals are simplicity and ease-of-use. It also has a strong focus on security and reliability, featuring a minimum of moving parts, usage of OpenSSH for transport (with other transports and pull modes as alternatives), and a language that is designed around auditability by humans–even those not familiar with the program.

It a widely used solution in the industry for various use cases, from environment's configuration to specific local installation for immutable infrastructure.

Our goal in this codelab is to play with Ansible, try some basics features and let you explore the wide ansible ecosystem by yourself.

### Installation

The instruction for installation can be found [here](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html)  

Check the pre-requisites and follow the installation instructions for your environment.

<aside class="negative">
Since Ansible is a trool to manage remote machines it choose to use ssh connection to target machine.
Ensure that you have ssh configuration well configured if you are on Windows environment.
</aside>


### Create target VM

Create a fresh VM with `vagrant` to use ansible on it with the following configuration
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.network :private_network, ip: "192.168.0.2"

  config.ssh.forward_agent    = true
  config.ssh.insert_key       = false
  config.ssh.private_key_path =  ["~/.vagrant.d/insecure_private_key","~/.ssh/id_rsa"]
  config.vm.provision :shell, privileged: false do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/$USER/.ssh/authorized_keys
      sudo bash -c "echo #{ssh_pub_key} >> /root/.ssh/authorized_keys"
      sudo apt-get update
      sudo apt-get install -y python
    SHELL
  end
end
```

Ansible use ssh to connect to target VM and execute command on machines.  
This configuration add your local machine ssh keys to the accepted configuration of the custom VM.


## Basics


### Inventory

Ansible works against multiple systems in your infrastructure at the same time. It does this by selecting portions of systems listed in Ansible’s inventory, which defaults to being saved in the location `/etc/ansible/hosts`. You can specify a different inventory file using the -i <path> option on the command line.

To work on your new configured VM, add it's ip to the ansible inventory file `/etc/ansible/hosts`
```bash
echo 192.168.0.2 >> /etc/ansible/hosts
```

By doing this you add your VM to the global inventory of ansible in the all group (if you don't have already some groupe configured in this file ...).

You can test the connection to your VM with the ansible command, using the `ping` module.  
```bash
ansible all -u vagrant -m ping 
```
The `-u` option define the suer to connect with on the VM.  
Th `-m` define the module to be executed on VMs from the all group

### Connection user

If you would like to access sudo mode, there are also flags to do that:

```bash
# as bruce
$ ansible all -m ping -u bruce
# as bruce, sudoing to root
$ ansible all -m ping -u bruce -b
# as bruce, sudoing to batman
$ ansible all -m ping -u bruce -b --become-user batman
```
(The sudo implementation is changeable in Ansible’s configuration file if you happen to want to use a sudo replacement. Flags passed to sudo (like -H) can also be set there.)


### Ad-hoc commands

Now run a live command on all of your nodes:
```bash
$ ansible all -u vagrant -a "/bin/echo hello"
```

Congratulations! You’ve just contacted your nodes with Ansible.  
It’s soon going to be time to: 

* read about some more real-world cases in Introduction To Ad-Hoc Commands
* explore what you can do with different modules
* learn about the Ansible Working With Playbooks language. Ansible is not just about running commands, it also has powerful configuration management and deployment features. 

There’s more to explore, but you already have a fully working infrastructure!

### Excercice

Start multiple VMs and configure ansible to run `hostname` to all your VM with one command

## Inventory

We already saw a basic invetory by adding our cutom VM in the inventory to work on it.
Now we're gonna look at you to build more complex inventory.

You can use multiple inventory files at the same time as described in Using multiple inventory sources, and/or pull inventory from dynamic or cloud sources or different formats (YAML, ini, and so on).

### Inventory basics: formats, hosts, and groups

The inventory file can be in one of many formats, depending on the inventory plugins you have. The most common formats are INI and YAML. A basic INI /etc/ansible/hosts might look like this:

```
mail.example.com

[webservers]
foo.example.com
bar.example.com

[dbservers]
one.example.com
two.example.com
three.example.com
```

The headings in brackets are group names, which are used in classifying hosts and deciding what hosts you are controlling at what times and for what purpose. Group names should follow the same guidelines as Creating valid variable names.

Here’s that same basic inventory file in YAML format:

```yaml
all:
  hosts:
    mail.example.com:
  children:
    webservers:
      hosts:
        foo.example.com:
        bar.example.com:
    dbservers:
      hosts:
        one.example.com:
        two.example.com:
        three.example.com:
```

#### Default groups

There are two default groups: all and ungrouped. The all group contains every host. The ungrouped group contains all hosts that don’t have another group aside from all. Every host will always belong to at least 2 groups (all and ungrouped or all and some other group). Though all and ungrouped are always present, they can be implicit and not appear in group listings like group_names.

#### Hosts in multiple groups

You can (and probably will) put each host in more than one group. For example a production webserver in a datacenter in Atlanta might be included in groups called [prod] and [atlanta] and [webservers]. You can create groups that track:
 - What - An application, stack or microservice (for example, database servers, web servers, and so on).
 - Where - A datacenter or region, to talk to local DNS, storage, and so on (for example, east, west).
 - When - The development stage, to avoid testing on production resources (for example, prod, test).

Extending the previous YAML inventory to include what, when, and where would look like:
```
all:
  hosts:
    mail.example.com:
  children:
    webservers:
      hosts:
        foo.example.com:
        bar.example.com:
    dbservers:
      hosts:
        one.example.com:
        two.example.com:
        three.example.com:
    east:
      hosts:
        foo.example.com:
        one.example.com:
        two.example.com:
    west:
      hosts:
        bar.example.com:
        three.example.com:
    prod:
      hosts:
        foo.example.com:
        one.example.com:
        two.example.com:
    test:
      hosts:
        bar.example.com:
        three.example.com:
```

You can see that one.example.com exists in the dbservers, east, and prod groups.

You can also use nested groups to simplify prod and test in this inventory, for the same result:

```yaml
all:
  hosts:
    mail.example.com:
  children:
    webservers:
      hosts:
        foo.example.com:
        bar.example.com:
    dbservers:
      hosts:
        one.example.com:
        two.example.com:
        three.example.com:
    east:
      hosts:
        foo.example.com:
        one.example.com:
        two.example.com:
    west:
      hosts:
        bar.example.com:
        three.example.com:
    prod:
      children:
        east:
    test:
      children:
        west:
```

### Adding variables to inventory

You can store variable values that relate to a specific host or group in inventory. To start with, you may add variables directly to the hosts and groups in your main inventory file. As you add more and more managed nodes to your Ansible inventory, however, you will likely want to store variables in separate host and group variable files.

#### Assigning a variable to one machine: host variables

You can easily assign a variable to a single host, then use it later in playbooks. In INI:
```
[atlanta]
host1 http_port=80 maxRequestsPerChild=808
host2 http_port=303 maxRequestsPerChild=909
```

In YAML:
```yaml
atlanta:
  hosts:
    host1:
      http_port: 80
      maxRequestsPerChild: 808
    host2:
      http_port: 303
      maxRequestsPerChild: 909
```

Unique values like non-standard SSH ports work well as host variables. You can add them to your Ansible inventory by adding the port number after the hostname with a colon:
`badwolf.example.com:5309`

Connection variables also work well as host variables:
```
[targets]

localhost              ansible_connection=local
other1.example.com     ansible_connection=ssh        ansible_user=myuser
other2.example.com     ansible_connection=ssh        ansible_user=myotheruser
```

#### Assigning a variable to many machines: group variables

If all hosts in a group share a variable value, you can apply that variable to an entire group at once. In INI:
```
[atlanta]
host1
host2

[atlanta:vars]
ntp_server=ntp.atlanta.example.com
proxy=proxy.atlanta.example.com
```

In YAML:
```yaml
atlanta:
  hosts:
    host1:
    host2:
  vars:
    ntp_server: ntp.atlanta.example.com
    proxy: proxy.atlanta.example.com
```

Group variables are a convenient way to apply variables to multiple hosts at once. Before executing, however, Ansible always flattens variables, including inventory variables, to the host level. If a host is a member of multiple groups, Ansible reads variable values from all of those groups. If you assign different values to the same variable in different groups, Ansible chooses which value to use based on internal rules for merging.


### Recap

We have seen some basic inventory practices, there is more on this subject and you can look at the official documentation to go further.
[Dynamic inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html) or [Using patterns for targeting](https://docs.ansible.com/ansible/latest/user_guide/intro_patterns.html)


## Intro to playbooks

Ansible Playbooks offer a repeatable, re-usable, simple configuration management and multi-machine deployment system, one that is well suited to deploying complex applications. If you need to execute a task with Ansible more than once, write a playbook and put it under source control. Then you can use the playbook to push out new configuration or confirm the configuration of remote systems. The playbooks in the ansible-examples repository illustrate many useful techniques. You may want to look at these in another tab as you read the documentation.

Playbooks can:
 - declare configurations
 - orchestrate steps of any manual ordered process, on multiple sets of machines, in a defined order
 - launch tasks synchronously or asynchronously

### Playbook syntax

Playbooks are expressed in YAML format with a minimum of syntax. If you are not familiar with YAML, look at our overview of YAML Syntax and consider installing an add-on for your text editor (see Other Tools and Programs) to help you write clean YAML syntax in your playbooks.

A playbook is composed of one or more ‘plays’ in an ordered list. The terms ‘playbook’ and ‘play’ are sports analogies. Each play executes part of the overall goal of the playbook, running one or more tasks. Each task calls an Ansible module.

### Playbook execution

A playbook runs in order from top to bottom. Within each play, tasks also run in order from top to bottom. Playbooks with multiple ‘plays’ can orchestrate multi-machine deployments, running one play on your webservers, then another play on your database servers, then a third play on your network infrastructure, and so on. At a minimum, each play defines two things:
 - the managed nodes to target, using a pattern
 - at least one task to execute

In this example, the first play targets the web servers; the second play targets the database servers.

```yaml
---
- name: Update web servers
  hosts: webservers
  remote_user: root

  tasks:
  - name: Ensure apache is at the latest version
    ansible.builtin.yum:
      name: httpd
      state: latest
  - name: Write the apache config file
    ansible.builtin.template:
      src: /srv/httpd.j2
      dest: /etc/httpd.conf

- name: Update db servers
  hosts: databases
  remote_user: root

  tasks:
  - name: Ensure postgresql is at the latest version
    ansible.builtin.yum:
      name: postgresql
      state: latest
  - name: Ensure that postgresql is started
    ansible.builtin.service:
      name: postgresql
      state: started
```

Your playbook can include more than just a hosts line and tasks. For example, the playbook above sets a remote_user for each play. This is the user account for the SSH connection. You can add other Playbook Keywords at the playbook, play, or task level to influence how Ansible behaves. Playbook keywords can control the connection plugin, whether to use privilege escalation, how to handle errors, and more. To support a variety of environments, Ansible lets you set many of these parameters as command-line flags, in your Ansible configuration, or in your inventory. Learning the precedence rules for these sources of data will help you as you expand your Ansible ecosystem.


#### Task execution

By default, Ansible executes each task in order, one at a time, against all machines matched by the host pattern. Each task executes a module with specific arguments. When a task has executed on all target machines, Ansible moves on to the next task. You can use strategies to change this default behavior. Within each play, Ansible applies the same task directives to all hosts. If a task fails on a host, Ansible takes that host out of the rotation for the rest of the playbook.

When you run a playbook, Ansible returns information about connections, the `name` lines of all your plays and tasks, whether each task has succeeded or failed on each machine, and whether each task has made a change on each machine. At the bottom of the playbook execution, Ansible provides a summary of the nodes that were targeted and how they performed. General failures and fatal “unreachable” communication attempts are kept separate in the counts.

#### Desired state and ‘idempotency’

Most Ansible modules check whether the desired final state has already been achieved, and exit without performing any actions if that state has been achieved, so that repeating the task does not change the final state. Modules that behave this way are often called ‘idempotent.’ Whether you run a playbook once, or multiple times, the outcome should be the same. However, not all playbooks and not all modules behave this way. If you are unsure, test your playbooks in a sandbox environment before running them multiple times in production.

#### Running playbooks

To run your playbook, use the [ansible-playbook](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html#ansible-playbook) command.
```bash
ansible-playbook playbook.yml -f 10
```
Use the `--verbose` flag when running your playbook to see detailed output from successful modules as well as unsuccessful ones.


### Ansible-Pull

Should you want to invert the architecture of Ansible, so that nodes check in to a central location, instead of pushing configuration out to them, you can.

The `ansible-pull` is a small script that will checkout a repo of configuration instructions from git, and then run `ansible-playbook` against that content.

Assuming you load balance your checkout location, `ansible-pull` scales essentially infinitely.

Run `ansible-pull --help` for details.

There’s also a clever playbook available to configure `ansible-pull` via a crontab from push mode.


### Verifying playbooks

You may want to verify your playbooks to catch syntax errors and other problems before you run them. The ansible-playbook command offers several options for verification, including `--check`, `--diff`, `--list-hosts`, `--list-tasks`, and `--syntax-check`.

#### `ansible-lint`

You can use `ansible-lint` for detailed, Ansible-specific feedback on your playbooks before you execute them. For example, if you run ansible-lint on the playbook called verify-apache.yml near the top of this page, you should get the following results:
```bash
$ ansible-lint verify-apache.yml
[403] Package installs should not use latest
verify-apache.yml:8
Task/Handler: ensure apache is at the latest version
```

The [ansible-lint default rules page](https://docs.ansible.com/ansible-lint/rules/default_rules.html) describes each error. For `[403]`, the recommended fix is to change `state: latest` to `state: present` in the playbook.


## Exercice

Create a playbook to create a new user and install a `nginx` server and use it on a VM.