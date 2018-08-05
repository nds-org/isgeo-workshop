# IS-GEO setup log

This page documents the steps followed to deploy Zero-to-JupyterHub on
Kubernetes on Jetstream (TACC) for the IS-GEO workshop.


## Create the Kubernetes Cluster

For this deployment we used the [Kubeadm Boostrapper with Terraform for OpenStack](https://github.com/nds-org/kubeadm-terraform).
Based on experience, we typically do the following:
* Create a small bastion VM that can be used to deploy/main the cluster 
* Use the bastion VM to `terraform apply` the cluster 

### OpenStack Prep

Create key pair via Horizon to be used by the bastion node then create the bastion
instance with the following attriburtes:

Bastion has the following attributes:
* flavor: m1.small
* source: JS-API-Featured-Ubuntu16-Jul-2-2018
* key pair: same as above
* security group: gssh
* Associate public IP address

### Prepare the bastion node

SSH into the bastion using the created key pair:

```
ssh -i ~/.ssh/key.pem ubuntu@BASTION_IP
```

Generate an SSH key pair.  This will be added to authorized keys on all
cluster instances for convenient access.

```
ssh-keygen
```


Optionally, setup ssh key forwarding to enable ssh'ing between instances in 
the cluster.  Create a new file `~/.ssh/config`:
```
host BASTION_IP
     ForwardAgent yes
```

Create `~/.bash_profile`:
```
if [[ -f ~/.bashrc ]] ; then
        . ~/.bashrc
fi

export PATH=~/bin:$PATH

ssh-agent
eval "$(ssh-agent)"
ssh-add ~/.ssh/id_rsa
```

Source the profile
```
. ~/.bash_rpfile
```

### Download the terraform binary

```
mkdir ~/bin && cd ~/bin
wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
unzip terraform_0.11.7_linux_amd64.zip && rm terraform_0.11.7_linux_amd64.zip
```

### Upload Ubuntu 16.04 LTS image

The data8 `kubeadm-bootstrap` process used to create the cluster require Ubuntu.
On Jetstream, it's sometimes difficult to decide which image to use, so we typically
`glance` a known image:

```
sudo apt install python3-openstackclient

mkdir glance && cd glance
wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
openstack image create   --disk-format qcow2 --container-format bare  --file xenial-server-cloudimg-amd64-disk1.img "Ubuntu 16.04 LTS"
```

### Create the cluster

With the bastion instance in place, we can now create the cluster:

Clone the `kubeadm-terraform` repo `nfs` branch:
```
git clone https://github.com/nds-org/kubeadm-terraform -b nfs
cd kubeadm-terraform
```

Edit the `variables.tf` file. The actual values used are in this repo.

Run terraform:
```
terraform init
terraform plan
terraform apply
```

If all goes well, you'll have a three-node cluster (master, storage, worker). This can easily be scaled up/down
by changing the `worker_count` value and running `terraform apply`.


## Deploy JupyterHub

Once the Kubernetes cluster is available, we can deploy JupyterHub.

### Note about NFS-client provisioner

We originally used the `rook` provisioner for dynamic volume support but ran into problems
when trying to scale the system. The `nfs` branch of the `kubeadm-terraform` instead
deploys an in-cluster NFS server on the storage node and the  `nfs-client-provisioner`.

### Setup Lego
We will eventually move to cert-manager, but today still use the `kube-lego` chart to 
automatically create TLS certificates.

On master:
```
sudo kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=support:default
sudo helm install --name lego stable/kube-lego --namespace=support --set config.LEGO_EMAIL=<your email> --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory
```

### Create NFS server
A requirement for many workshops is the ability to mount shared storage that all users to 
write to. To achieve this, we deploy an instance-specific NFS server on the storage node.

On master:
```
kubectl create ns isgeohub
kubectl create -n isgeohub -f nfs-server.yaml
kubectl get svc -n isgeohub
```

Get the IP address of the service to configure in JupyterHub.

### Configure JupyterHub

Using the configuration file provided in this repo, update relevant settings.

On master:
```
sudo helm install jupyterhub/jupyterhub --version=v0.6 --name=isgeohub --namespace=isgeohub -f config_jupyterhub.yaml
```

At this point, you should have a JupyterHub instance running using the NFS-client provisioner 
with shared storage mounted into each running container.


### Load test the server

We use  `yuvipanda/hubtraf` to confirm the system can support the required number of users.

```
mkdir loadtest
cd loadtest
```

Create a JupyterHub `config.yaml` that will be used for testing only. This should be identical to the primary configuration except that it must use the default authenticator and the classic notebook by default.

Install the helm chart for the test instance. This will be removed
```
sudo helm install jupyterhub/jupyterhub --version=v0.6 --name=test --namespace=test -f config.yaml
```


```
git clone https://github.com/yuvipanda/hubtraf
```

Configure `hubtraf` by editing `helm-chart/values.yaml`
```
completions: 1
image:
  repository: craigwillis/hubtraf
  tag: latest
  pullPolicy: Always
resources: {}

hub:
  url: "https://test.isgeo.ndslabs.org"

users:
  count: 50
  startTime:
    max: 300
  runTime:
    min: 300
    max: 600
```
 
Run the helm chart:
```
sudo helm install --namespace=hubtraf  --name=hubtraf hubtraf/helm-chart/
```
     
Monitor the test:
```
watch "kubectl get pods -n test"
```

Delete the helm chart and test namespace:
```
sudo helm delete --purge hubtraf
kubectl delete ns test
```

