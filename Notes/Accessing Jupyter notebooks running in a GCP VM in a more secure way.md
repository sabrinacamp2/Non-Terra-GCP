# Accessing Jupyter notebooks running in a GCP VM in a more secure way

### TL;DR
You only have to follow these steps once. 
- [Clone this repository](#clone).
- [Remove unsafe settings.](#unsafe-settings) 
- [Allow your VM to send traffic out to the internet, e.g. access websites, APIs.](#allow-internet)  

New quickstart steps, use this every time you access your VM.
- If you set up your VM using the docs in this repository, [these are your new quickstart steps](#revised-quickstart).
### What's the problem?
- The way we access our Jupyter notebooks running in the VM is by navigating to the VM's associated external IP address and the port number (e.g. `external_ip:8080`). We created a firewall rule to allow access to this port. When setting up this firewall rule, we allowed _any public IP address_ can connect to `external_ip:8080`. **Allowing any public IP to access the port increases the risk of brute-force attacks, where attackers might try to guess your credentials (Jupyter notebook password or token).**
	- Note: Ports like 8080 and 5000 are commonly used for web applications, making it easier for someone to guess the port and potentially access the notebook.
### Options
To reduce risk, you have a few options:
- **(This tutorial) Do not associate an external IP with your VM**: Instead, connect to the VM via an encrypted tunnel ([IAP tunneling](https://cloud.google.com/iap/docs/using-tcp-forwarding)) and forward the Jupyter server port to your _local machine_.
  - **Advantages**:
    - The VM is not exposed to the public internet; access is through Google's infrastructure only.
    - The Jupyter server is not directly accessible via the web at all. 
- **(Not covered here) Limit externally accessible IP ranges**: If you do use an external IP, restrict access to your VM’s ports by specifying trusted IP addresses (e.g., home network, office network). Only these IPs will be able to access the port on which your notebook is running.
	- Create a firewall rule to do this. 

### Clone repository<a name="clone"></a>
You only have to do this step once. 
1. Clone this repository
	```bash
	git clone https://github.com/sabrinacamp2/Non-Terra-GCP.git
	```
2. Navigate to the `Non-Terra-GCP/VM-helper-scripts` directory. Open `config.sh` in a text editor or command-line text editor. Edit variables to match the instance name and project that is specific to you. My information is set as an example.
	```bash
	cd Non-Terra-GCP/VM-helper-scripts
	vim config.sh
	```
3. Set bash scripts in the VM-helper-scripts folder as executable
	```bash
	chmod +x *.sh
	```

### Remove not safe settings<a name="unsafe-settings"></a>

1. Remove the VM’s external IP address:
    
    - Navigate to **VM Instances** -> Select your VM -> Click **Edit** -> Go to **Network Interfaces** -> Click the dropdown next to **Default** -> Click the dropdown next to **External IPv4 Address** -> Select **None** and save changes.<br><br>
	   <img src="../Attachments/remove_external.png" alt="remove_external" width = 70%)><br>
4. Remove the firewall rule allowing anyone to access your VM's 8080 port:
    
    - Navigate to **VPC Network** -> **Firewall Policies** -> Delete any rule you created when following the documentation that allowed all source IP ranges to access port 8080.<br><br>
	   <img src="../Attachments/delete_jupyter.png" alt="delete_jupyter" width = 70%)><br>


### Allow your VM to send traffic out to the internet<a name="allow-internet"></a>
- **Set up Cloud NAT**
	1. At the top of the google cloud console, click the magnifying glass and search for `Cloud NAT`, click that option.<br><br>
	   <img src="../Attachments/cloud_nat_search.png" alt="cloud_nat_search" width = 70%)><br>
	2. Click `CREATE CLOUD NAT GATEWAY`<br><br>
	   <img src="../Attachments/cloud_nat_page.png" alt="cloud_nat_page" width = 70%)><br>
	3. Fill in below options, replacing `vanallen-scamp` with your project id. Click the dropdown beside `Cloud Router`, and select `CREATE NEW ROUTER`.<br><br>
	   <img src="../Attachments/cloud_nat_intro.png" alt="cloud_nat_intro" width = 70%)><br>
	4. Fill in `Name` as project ID, and click create. <br><br>
	   <img src="../Attachments/cloud_router.png" alt="cloud_router" width = 70%)><br>
	5. Final configuration should look like this, but with your project ID. Click create. <br><br>
	   <img src="../Attachments/final_cloud_nat_config.png" alt="final_cloud_nat_config" width = 70%)><br>
- **Create firewall rule allowing VM to send traffic out to the internet.**
	1. Navigate to `VPC Network` -> `Firewall`
	2. Click `CREATE FIREWALL RULE`<br><br>
	   <img src="../Attachments/create_firewall_rule.png" alt="create_firewall_rule" width = 70%)><br>
	3. Create firewall rule exactly like below. <br><br>
	   <img src="../Attachments/egress_firewall_rule.png" alt="egress_firewall_rule" width = 70%)><br>
	4. Click create
### Revised quickstart steps:<a name="revised-quickstart"></a>
If you set up this VM using the [Introduction-to-GCP-VMs-and-using-Terra-notebook-environments](../Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md) doc in this repository, these will be your new quickstart steps:

**In local terminal**
```bash
# navigate to cloned repository directory, will be dependent on where you cloned it to
cd Non-Terra-GCP/VM-helper-scripts

# start port forwarding and interactive VM session
./start_vm.sh
```
**Once in GCP VM**
```bash
# start screen on VM for your jupyter notebook process
screen -S jupyter_notebook
```

```bash
# mount persistent disk
sudo mount -o discard,defaults /dev/disk/by-id/{persistent-disk-name} /mnt/disks/{folder-name}

# start up terra notebook environment and jupyter notebook
sudo docker run -e R_LIBS='/home/jupyter/packages' --rm -it -u jupyter -p 8080:8080 -v /mnt/disks/{folder-name}:/home/jupyter --entrypoint /bin/bash {terra-docker-image-path}

# if using jupyter lab
jupyter-lab --no-browser --port=8080

# if using jupyter notebook
jupyter-notebook --no-browser --port=8080
```

- If using jupyter lab, go to `localhost:8080` in a web browser to access your notebooks. 
- If using jupyter notebooks, go to `localhost:8080/notebooks` in a web browser to access your notebooks. 

### When things go wrong
- **Suddenly, you can't load your notebook**<br><br>
	   <img src="../Attachments/connection_error.png" alt="connection_error" width = 70%)><br>
	- This often means your ssh command was interrupted, causing the forwarding of the VM's port 8080 to your local computer's port 8080 to stop. However, the Jupyter notebook process itself is still running. To resume access:
		```bash
		# navigate to cloned repository directory, will be dependent on where you cloned it to
		cd Non-Terra-GCP/VM-helper-scripts
		
		# restart port forwarding
		./restart_port_forwarding.sh
		# re-load localhost:8080 in browser, should be where you left off when connection broke
		```

- **Error: "Port already in use" when running the Docker or Jupyter command** in the GCP VM:  
	- This happens when the port is still occupied by a process that wasn't fully shut down. Restarting the VM should resolve the issue.