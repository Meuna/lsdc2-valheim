packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  lsdc2-gamename  = "valheim"
  lsdc2-user      = "lsdc2"
  lsdc2-home      = "/lsdc2"
  lsdc2-gid       = 2000
  lsdc2-uid       = 2000
  lsdc2-pilot-url = "https://github.com/Meuna/lsdc2-pilot/releases/download/v0.5.2/lsdc2-pilot"
  lsdc2-service   = "lsdc2.service"
  game-savedir    = "/lsdc2/savedir"
  game-savename   = "lsdc2"
  game-port       = 2456
}

# Source image
source "amazon-ebs" "ubuntu-noble-latest" {
  ami_name            = "lsdc2/images/${local.lsdc2-gamename}"
  spot_instance_types = ["m6a.large", "m6i.large", "m7i-flex.large", "m7i.large", "m5.large", "m5a.large"]
  spot_price          = "0.05"
  tags = {
    "lsdc2.gamename" = "${local.lsdc2-gamename}-ec2"
  }
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_type           = "gp3"
    throughput            = 400
    iops                  = 4000
    delete_on_termination = true
  }
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-noble*24.04*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username          = "ubuntu"
  force_deregister      = true
  force_delete_snapshot = true
}

# Provisionning
build {
  name = "lsdc2/packer/${local.lsdc2-gamename}"
  sources = [
    "source.amazon-ebs.ubuntu-noble-latest"
  ]

  # Provision server packets
  provisioner "shell" {
    inline = [
      "sudo add-apt-repository -y multiverse",
      "sudo dpkg --add-architecture i386",
      "echo steamcmd steam/license note '' | sudo debconf-set-selections",
      "echo steamcmd steam/question select 'I AGREE' | sudo debconf-set-selections",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl steamcmd",
    ]
  }

  # Provision lsdc2 stack
  provisioner "file" {
    sources     = ["start-server.sh", "update-server.sh"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo groupadd -g ${local.lsdc2-gid} -o ${local.lsdc2-user}",
      "sudo useradd -g ${local.lsdc2-gid} -u ${local.lsdc2-uid} -d ${local.lsdc2-home} -o --no-create-home ${local.lsdc2-user}",
      "sudo mkdir -p ${local.lsdc2-home}",
      "sudo mv /tmp/* ${local.lsdc2-home}",
      "sudo chown -R ${local.lsdc2-user}:${local.lsdc2-user} ${local.lsdc2-home}",
      "sudo chmod u+x ${local.lsdc2-home}/*.sh",
      "sudo -u ${local.lsdc2-user} LSDC2_HOME=${local.lsdc2-home} ${local.lsdc2-home}/update-server.sh"
    ]
  }

  # Provision LSDC2 service
  provisioner "file" {
    content     = <<EOF
[Unit]
Description=LSDC2 proces
After=network.target

[Service]
User=root
EnvironmentFile=${local.lsdc2-home}/lsdc2.env
ExecStart=lsdc2-pilot ${local.lsdc2-home}/start-server.sh
Restart=no

[Install]
WantedBy=multi-user.target
EOF
    destination = "/tmp/${local.lsdc2-service}"
  }

  provisioner "file" {
    content     = <<EOF
LSDC2_USER=${local.lsdc2-user}
LSDC2_HOME=${local.lsdc2-home}
LSDC2_UID=${local.lsdc2-uid}
LSDC2_GID=${local.lsdc2-gid}
LSDC2_SNIFF_FILTER="udp dst port ${local.game-port}"
LSDC2_CWD=${local.lsdc2-home}
LSDC2_PERSIST_FILES="${local.game-savename}.db;${local.game-savename}.fwl"
LSDC2_ZIPFROM=${local.game-savedir}/worlds_local
GAME_SAVEDIR=${local.game-savedir}
GAME_SAVENAME=${local.game-savename}
GAME_PORT=${local.game-port}
EOF
    destination = "/tmp/lsdc2.env"
  }

  provisioner "shell" {
    inline = [
      "sudo curl -L ${local.lsdc2-pilot-url} -o /usr/local/bin/lsdc2-pilot",
      "sudo chmod +x /usr/local/bin/lsdc2-pilot",
      "sudo mv /tmp/${local.lsdc2-service} /etc/systemd/system/${local.lsdc2-service}",
      "sudo mv /tmp/lsdc2.env ${local.lsdc2-home}/lsdc2.env",
      "sudo chown root:root ${local.lsdc2-home}/lsdc2.env",
    ]
  }

  # Local lsdc2-pilot for debug purpose
  #  provisioner "file" {
  #    source      = "lsdc2-pilot"
  #    destination = "/tmp/"
  #  }
  #  provisioner "shell" {
  #    inline = [
  #      "sudo mv /tmp/lsdc2-pilot /usr/local/bin/lsdc2-pilot",
  #      "sudo chmod +x /usr/local/bin/lsdc2-pilot",
  #    ]
  #  }

  # Clean up
  provisioner "shell" {
    inline = [
      "sudo apt-get clean",
      "sudo rm -rf /root/.steam /var/lib/apt/lists/* /tmp/* /var/tmp/*",
      "sudo find / -name authorized_keys -exec rm -f {} \\;"
    ]
  }

}
