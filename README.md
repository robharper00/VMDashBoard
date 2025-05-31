# VMDashBoard
The page places a html on a network share drive. When this HTML is opened in a browser, users can access and see the status of every VM on the machine that hosts the network file share.

V1 of this product consit of a power shell script that can be ran on any client computer. The powershell script configures the computer, and outputs HTML that can opened. The webpage is set up to where a user can input the IP or Computer Name can be entered and then open RDP to create a session.

V2 of the webpage adds the capability of listing all VMs of a computer on the HTML and automatically updating that list every 10 minutes. The webpage then allows any users on the network remote into any VM on the host computer, remote into the host, or remote into any computer in which the computer name is known.
