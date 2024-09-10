# Accessing Jupyter notebooks running in a GCP VM in a more secure way

### What's the problem?
- The way we access our jupyter notebooks running in the VM is by navigating to the VM's associated external IP address and the port number (e.g. 8080) that we created a firewall rule to allow access to. When creating this firewall rule, we specified that _any public IP address_ can connect to `external_ip:8080`. **Allowing any public IP to access increases the risk of brute-force attacks, where attackers try to guess your credentials (jupyter notebook password or token).**
	- Note: port 8080 and 5000 are standard, so it would be easy for someone to guess your port.
### Options
To reduce risk, you have a few options:
- **(This tutorial) Do not have an external IP associated with your VM**: Connect to the VM via an encrypted tunnel ([IAP tunneling](https://cloud.google.com/iap/docs/using-tcp-forwarding)) and forward the Jupyter server port to your _local machine_.
  - **Advantages**:
    - The VM is not exposed to the public internet; access is through Google's infrastructure only.
    - The Jupyter server is not directly accessible via the web at all. 
- **(Not covered here) Limit externally accessible IP ranges**: Restrict access to your VM's port by specifying trusted IP addresses (e.g., home network, office network). Only these IPs can access the port that your notebook is running on.
	- [ML GROUPS DOCS ON THIS?]

### How to connect:
1. Start a screen on your local machine so that the ssh and port forwarding continues even if your terminal closed
	```bash
	screen -S port_forwarding
	```
1. In the screen, SSH into the VM adding flags for the tunnel and port forwarding:
   ```bash
   gcloud compute ssh --zone "us-central1-a" "{instance-name}" --project "{project-id}" --tunnel-through-iap -- -L 8080:localhost:8080
   ```

2. If you set up this VM using the [Non-Terra GCP documentation](../Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md), follow the remaining [quickstart steps](../Introduction-to-GCP-VMs-and-using-Terra-notebook-environments.md#quickstart) below to get your notebooks up and running:
	```bash
	# start screen on VM
	screen -S jupyter_notebook
	
	sudo mount -o discard,defaults /dev/disk/by-id/{persistent-disk-name} /mnt/disks/{folder-name}
	
	sudo docker run -e R_LIBS='/home/jupyter/packages' --rm -it -u jupyter -p 8080:8080 -v /mnt/disks/{folder-name}:/home/jupyter --entrypoint /bin/bash {terra-docker-image-path}
	
	jupyter-lab --no-browser --port=8080
	
	```
3. Access the notebook:
    
    - Open your browser and go to `localhost:8080`
2. Working with the screen
	- If you want to close your terminal and keep the process running, detach from the screen
		```
		press CTRL + A
		press CTRL + D
		```
	- If you want to get back into it
		```bash
		screen -r port_forwarding
		```



### Remove not safe settings

1. Remove the VM’s external IP address:
    
    - Navigate to **VM Instances** -> Select your VM -> Click **Edit** -> Go to **Network Interfaces** -> Click the dropdown next to **Default** -> Click the dropdown next to **External IPv4 Address** -> Select **None** and save changes.<br><br>
	   <img src="../Attachments/remove_external.png" alt="remove_external" width = 70%)><br>
4. Remove the firewall rule allowing anyone to access your VM's 8080 port:
    
    - Navigate to **VPC Network** -> **Firewall Policies** -> Delete any rule you created when following the documentation that allowed all source IP ranges to access port 8080.<br><br>
	   <img src="../Attachments/delete_jupyter.png" alt="delete_jupyter" width = 70%)><br>



### When things go wrong
- All of the sudden you can't load your notebook.<br><br>
	   <img src="../Attachments/connection_error.png" alt="connection_error" width = 70%)><br>
	- This can mean that your ssh command (running in the `port_forwarding` screen gets interrupted, so the port stops being forwarded to your local computer. We can re-establish the connection and port forwarding, which will resume your access to the notebook. 
		```bash
		# on your local terminal, reconnect to screen
		# where port forwarding command was run
		screen -r port_forwarding
		# if you see broken pipe or some other error...
		# re-establish connection and port forwarding
		gcloud compute ssh --zone "us-central1-a" "{instance-name}" --project "{project-id}" --tunnel-through-iap -- -L 8080:localhost:8080
		# re-load localhost:8080 in browser, should be where you left off when connection broke
		```

- Error about the port already being used when running the docker command or when running the jupyter command. This happens when there is a process running in that port that isnt fully shut down. Restarting the VM should remedy the issue. 