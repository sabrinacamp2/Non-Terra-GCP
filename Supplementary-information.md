
# Supplementary information

## Conda environment and kernels

We can also use different conda environments within a Jupyter notebook using kernels. S/O Erica Pimenta for providing some insight into this. The main idea is that if you want to use a conda environment with a jupyter notebook, you need to have `ipykernel` installed in the environment. If you want the R kernel, you would need to have `r-irkernel` installed in the environment. For example, the below command would create an environment and associated python kernel for the `scanpy_env`. You could then use the `scanpy_env` python kernel and associated packages in a jupyter notebook.
```bash
conda create --name scanpy_env scanpy ipykernel
```

## Working with the screen function
Our Jupyter notebook process is running in a screen on the GCP VM. This makes it so that even if you lose connection to your VM, exit the terminal, etc, the Jupyter process will still be running and you will still be able to access it at `localhost:8080`. Below are some helpful tips for working with screens if you haven't before.
```bash
# disconnect from the screen and you should still be able to access notebook in browser
press CTRL + A
press CTRL + D

## other useful functions with screens
# list screens
screen -ls
# connect back to a screen
screen -r {screen-name}
# end all detatched screens
screen -ls | grep Detached | cut -d. -f1 | awk '{print $1}' | xargs kill

```

## How the boot disk image used in this tutorial was created
Steps to how I created one of the boot disk images, `terra-docker-image-100-boot-20230720.`
1. Install docker. 
   - The Terra notebook environments are [docker images](https://github.com/DataBiosphere/terra-docker). Therefore, in order to utilize these environments in our VM instances, we first have to install docker. I'm following [this](https://tomroth.com.au/gcp-docker/) tutorial which assumes a Debian Linux distribution, which is what GCP uses. 
	   ```bash
	   sudo apt update
	   sudo apt install --yes apt-transport-https ca-certificates curl gnupg2 software-properties-common
	   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
	   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
	   sudo apt update
	   sudo apt install --yes docker-ce
	   ```
2. Pull the following Terra dockers
	1. R/Bioconductor: us.gcr.io/broad-dsp-gcr-public/terra-jupyter-bioconductor:2.1.11
	2. Python: us.gcr.io/broad-dsp-gcr-public/terra-jupyter-python:1.0.15
	3. Default: us.gcr.io/broad-dsp-gcr-public/terra-jupyter-gatk:2.2.14

## Create a boot disk image with different notebook environments<a name="newboot"></a>
1. [SSH into your VM](Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#start-vm) that was created with one of the tutorial book disk images. e.g., `terra-docker-image-100-boot-20230720`
1. List out currently cached docker images 
	``` bash
	sudo docker images
	```
	1. If you want to remove all cached images
		``` bash
		sudo docker system prune -a
		```
	1. If you want to remove a specific image,
		``` bash
		docker rmi {image-id}
		```
1. Pull the docker images you want
	``` bash
	docker pull us.gcr.io/broad-dsp-gcr-public/terra-jupyter-bioconductor:2.2.4
	```
1. Stop the VM instance
2. Go to the disks tab in the UI, find the boot disk associated with the VM you were SSH'd into, and select the three dot button to the far right
3. Select create image, fill out sections making sure the location is regional, and create it. 
4. Go to VM(s) you've created where you want to use these different notebook environments and click Edit. 
5. Select detatch boot disk, then select configure boot disk. 
6. Select the custom images tab, change source project to your own, and select the disk image you just created. 
7. Save changes

Next time [you spin up this VM](Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#quickstart), you will be able to use these different notebook environments by editing the `{terra-docker-image-path}` to one that you pulled. 


## Sudo access on docker
- To be able to use the `sudo` command, you have to enter the docker as the root user. Generally wouldn't recommend accessing the docker as the root user because of file/folder permissions weirdness later. 
	```bash
	sudo docker run -e R_LIBS='/home/jupyter/packages' --rm -it -u root -p 8080:8080 -v /mnt/disks/{folder-name}:/home/jupyter --entrypoint /bin/bash {terra-docker-image-path}
	```
	
	```bash
	#example
	sudo docker run -e R_LIBS='/home/jupyter/packages' --rm -it -u root -p 8080:8080 -v /mnt/disks/scamp-singlecell:/home/jupyter --entrypoint /bin/bash us.gcr.io/broad-dsp-gcr-public/terra-jupyter-bioconductor:2.1.11
	```

## Using FISS to access Terra data tables

First, you need to set up google cloud authorization to allow your code to read your google cloud credentials. This is different from [the previously mentioned google cloud authorization step](Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#gcloudauth). The difference between `gcloud auth login` and `gcloud auth application-default login` talked about more in depth in [this stack overflow post](https://stackoverflow.com/questions/53306131/difference-between-gcloud-auth-application-default-login-and-gcloud-auth-logi).

Once you are in the GCP VM and running your chosen Terra docker, type the below command in the terminal:

```bash
gcloud auth application-default login --no-browser
```

Copy the terminal output command that begins with `gcloud auth application-default login --remote-bootstrap=` into a separate terminal (e.g. the one on your local computer) and press enter. This should open up the web browser where you will log in with your broad google account and authorize. Then, copy the terminal output from your alternative/local terminal and paste it into the GCP VM terminal. This completes the authorization needed to allow your code to interact with your google cloud credentials. To validate that this process worked, check if the following file exists:  `/home/jupyter/.config/gcloud/application_default_credentials.json`. 

Now that you are authenticated, you can use the [`FISS`](https://github.com/broadinstitute/fiss) python package to interact with the Terra data model. An example use case is below where I'm accessing the sample table from the `scATAC_matchedWES` workspace.

```python
from firecloud import fiss
import io
import pandas as pd

project="vanallen-firecloud-nih"
workspace="scATAC_matchedWES"
bucket="fc-a4718cd6-cff4-49de-bb50-30f38691a1ab/"

r = fiss.fapi.get_entities_tsv(project, workspace, 'sample')
sample_table = pd.read_csv(io.BytesIO(r.content), encoding='utf-8', sep='\t') 

```
## Using an existing persistent disk with multiple VMs
A persistent disk can only be attached and used by one VM at a time. However, sometimes you want to go from using your persistent disk with "VM1" to using it with "VM2". There are two ways to go about doing this.
1. You can do this from the GCP UI by first editing "VM1" and removing the disk from the `Additional disks` section. Save the edit, then edit "VM2" and select "Attach an existing disk" in the `Additional disks` section. Select the disk you removed from "VM1", save the edit, and then you can proceed [as usual to access the VM](Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#quickstart).
2. You can do this all from the CLI. S/O Laura Valderrábano for providing the code and comments for this,
	1. Unmount the persistent disk. First you need to SSH into "VM1" where the disk is currently attached and unmount it.
	   ```bash
	   gcloud compute ssh --zone "us-central-a" "{instance-name}" --project "{project-id}"

		sudo umount /dev/disk/by-id/{persistent-disk-name}
		```

		```bash
		#example
		gcloud compute ssh --zone "us-central1-a" "lvalderr-cpu-16" --project "vanallen-lvalderr"

		sudo umount /dev/disk/by-id/scsi-0Google_PersistentDisk_lvalderr-singlecell
		```

	2. Detach the persistent disk from "VM1" in a new terminal window/tab.
		```bash
		gcloud compute instances detach-disk {instance-name} --disk=disk-name
		```

		```bash
		gcloud compute instances detach-disk --zone "us-central1-a" "lvalderr-cpu-128" --disk=lvalderr-singlecell
		```

	3. Attach the disk to "VM2". In the same terminal window as above, attach the disk to "VM2" with read and write permissions.
		```bash
		gcloud compute instances attach-disk --zone "us-central1-a" "{instance-name}" --disk={disk-name} --mode=rw
		```

		```bash
		#example
		gcloud compute instances attach-disk --zone "us-central1-a" "lvalderr-cpu-128" --disk=lvalderr-singlecell --mode=rw
		```

	4. Follow [quickstart steps](Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#quickstart) to access "VM2". The disk should now be accessible from "VM2".

## Increase size of existing persistent disk
- Follow steps from the [google cloud documentation](https://cloud.google.com/compute/docs/disks/resize-persistent-disk). This requires both increasing the size of the disk AND resizing the file system and partitions as a non-boot disk. Follow the steps for a linux VM. 

## Restore data from snapshot
Did you mess up beyond belief and now you want to re-create your disk from a snapshot/ backup? It's ok! 

Follow [these](https://cloud.google.com/compute/docs/disks/restore-snapshot) steps to create a new persistent disk based on a snapshot. Then, you can navigate in the console to the VM you want to use this disk with, scroll down to the Additional disks section, remove any attached disks, and attach your newly created disk. 

SSH into the above VM, and find out what this new persistent disk name is. 
```bash
ls /dev/disk/by-id/
```

Now, follow the second part of the [quickstart steps](Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#quickstart) - "I created a new VM (e.g., needed more memory). What all do I have to do to get jupyter up and running again?" being sure to fill in your new folder and disk name. You should be good to go now! When you are comfortable, I would recommend deleting your old disk so we don't pay for extra storage.
## Common issues
- Jupyter lab/notebook did not load in the browser
	- Check for leading or trailing spaces in the lines you added to the jupyter config file. 
- Unable to mount persistent disk because it is attached to another VM instance. 
	- Through the UI, edit the VM instance that has your disk attached. In the `Additional disks` section, detatch your disk. Once that is saved, edit the VM instance you are now using, navigate to the `Additional disks` section and attach your disk. 

## To do
- Clarify disk terminology
- Conda environment guidance
- I have multiple workspaces w/ Terra notebooks -- what do I do? Temp draft of steps
	- Create a persistent disk for each
	- Copy over files from each into each
	- attach/detatch to VM 