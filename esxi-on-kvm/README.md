Notes from deploying this on an r5b.metal in EC2
---
    I used the centos 8 appstream image AWS makes from the marketplace. 
    I gave the host 2 ENIs both on the same private subnet.
    I deployed a managed AD instance that also has its domain controllers on the same private subnets.  Note: not Simple AD, normal managed AD.

Steps
---
    sudo su -
        * note: the scripts expect you to be root
  
    systemctl enable --now cockpit.socket
    yum install wget python38* epel-release git -y
    yum update -y
    yum install awscli s3cmd -y

        [this next part is just so cloudwatch agent log stuff works and is optional]
	
        wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm 
        vi /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json 
            (manually insert json base file)
            (manually create new log group called nest-test-centos-8-appstream)
        sed -i "s/INSTANCELOGSPLACEHOLDER/nest-test-centos-8-appstream/g" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    mkdir -p /scripts
    cd /scripts
    git clone https://github.com/seahow-uk/vmware-admin-scripts.git
    cd vmware-admin-scripts
    chmod -R 700 *
    cd esxi-on-kvm/ISO
    mkdir vcsa
    cd vcsa

        [you will need to pre stage these in an s3 bucket for this next 2 commands to work, or you could manually get them from VMware]

        aws s3 cp s3://$S3PATH/VMware-VCSA-all-7.0.3-20395099.iso .
        aws s3 cp s3://$S3PATH/VMware-VCSA-all-6.7.0-15132721.iso .

    cd /scripts/vmware-admin-scripts/esxi-on-kvm

    vi main.sh

        [Here you will have to manually set the parameters it wants at the top of the file]
    
    ./main.sh

