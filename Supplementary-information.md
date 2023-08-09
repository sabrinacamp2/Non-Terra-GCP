
# Supplementary information

## Conda environment and kernels
By default, conda environments are placed in `/opt/conda/envs`. As I mentioned earlier, only files in `/home/jupyter` will be saved to the persistent disk, so by default the created conda environments **would be lost** if you created a new VM. 

To keep your conda environments, edit the conda configuration to save the environments to a location that is on the persistent disk. 
```bash
conda config --append envs_dirs /home/jupyter/envs
```

We can also use different conda environments within a Jupyter notebook using kernels. S/O Erica Pimenta for providing some insight into this. The main idea is that if you want to use a conda environment with a jupyter notebook, you need to have `ipykernel` installed in the environment. If you want the R kernel, you would need to have `r-irkernel` installed in the environment. For example, the below command would create an environment and associated python kernel for the `scanpy_env`. You could then use the `scanpy_env` python kernel and associated packages in a jupyter notebook.
```bash
conda create --name scanpy_env scanpy ipykernel
```

## Keep process on VM running when you shut computer/ lose wifi/ close terminal
To keep a process in the VM (e.g. a notebook session) running when you shut your computer/lose wifi connection/close terminal/etc, you need to use the `screen` function. 
```bash
# SSH into the VM if not already
gcloud compute ssh --zone "us-central1-a" "{instance-name}" --project "{project-id}"

# start screen
screen

# start process that you want to keep running regardless of connection
# example, a jupyter notebook
sudo docker run -e R_LIBS='/home/jupyter/packages' --rm -it -u jupyter -p 8080:8080 -v /mnt/disks/{folder-name}:/home/jupyter --entrypoint /bin/bash {terra-docker-image-path}

jupyter-lab --no-browser

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
Steps to how I created the boot disk image `terra-docker-image-100-boot-20230720`
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
- Add Laura's notes on PD mount/unmount attach/detach via command line