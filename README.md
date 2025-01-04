# DevOps Automation Challenge
This is a project for demonstrating the ability to automate processes of provisioning and configuration management in a live environment with the latest DevOps practices.

## Overview
The task is designed to showcase the skill level in automation, configuration management, and scripting.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Interview-questions](#Interview-questions)
- [Installation](#installation)
- [Usage](#usage)
- [Description](#Description)
- [Pre-conditions](#pre-conditions)
- [Contributing](#contributing)
- [License](#license)

## Interview-questions:
1. Provision a New Virtual Machine
a. Use Terraform (or any preferred IaC tool) to provision a new Windows EC2
instance on AWS or another cloud provider.

2. Automate Machine Setup
a. Create an automation process to configure the machine after launch. You
may use Ansible, user_data scripts, or any other preferred automation tool.
The automation should achieve the following:
i. Install IIS and configure it to host a new website.
ii. Deploy the website from the following repository as a reference:
https://github.com/AzureWorkshops/samples-simple-iis-website
iii. Ensure the IIS setup is ready to automatically deploy any .NET
application in the future.
3. Install and Configure Prometheus Exporter
a. Install a Prometheus exporter (e.g., Windows Exporter).
b. Configure the exporter to expose server metrics on localhost:9090.
4. Create a Scheduled Task
a. Implement a scheduled task (should be done automatically when machine
will start) that runs every 5 minutes to:
b. Perform an HTTP POST request to send all Prometheus data
(localhost:9090) to a temporary API endpoint like Pipedream
RequestBin.
5. Develop a PowerShell Script
a. Write a PowerShell script to:
  i. Generate a dump file of the deployed IIS website automatically.
  ii. Ensure the script is stored on the VM.
6. Generate IIS Usage Report
• Based on the logs from IIS, create a script or tool that generates a summary/report
including:
o The most active times for the website.
o A summary of errors encountered (e.g., 404, 500 errors).
o User browser statistics (e.g., Chrome, Firefox, etc.).
• Provide the report in a human-readable format, such as JSON, CSV, or an HTML
page.
7. Harden the Instance
• Apply security hardening measures to the instance to make it production-ready.

## Features
The following project is completing all the interview questions mentioned Above with only one terraform apply, and a few pre-requisites
![Project Screenshot](![image](https://github.com/user-attachments/assets/5388e0a9-8546-48b3-9779-c0591d78ff3a)

## Installation
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [IIS](https://learn.microsoft.com/en-us/iis/)

## Usage
This section will describe the Project usage and Installation:
  1. Start with cloning the repository with git:
     ```
     git clone https://github.com/Dan4ik7/Infigo
     ```
  2. Connect to you AWS account and create a Key-pairs for the instance so you would be able to connect via RDP to the instance
     Key-Pairs Path: EC2 -> Network & Security -> Key Pairs -> Create a .pem file and download it
  
  3. Go to the cloned Repository, inside the terraform folder: Initialize terraform
     a. First set up your aws Credentials:
        *For ease of ussage, I have exported the access keys directly in CLI as a environment vars:
        ```
        $env:AWS_ACCESS_KEY_ID="<KEY_ID>"
        $env:AWS_SECRET_ACCESS_KEY="<SECRET_ID>"
        ```
  4. Apply configurations:
      ```
      terraform plan
      terraform apply --auto-approve
      ```
  5. Connect to the Instance and Monitor the configuration Process:
     The terraform has created the security group to allow RDP trafiic. In order to connect to the instance via RDP go to your aws account:
     EC2 -> Instances -> Click on running instance -> Connect -> Click on RDP Client -> Click on Get Password and upload the .pem file created
     earlier in key pairs -> Decrypt Password -> Copy Password -> Click on Download Remote Desktop file and login to the EC2:
     ![image](https://github.com/user-attachments/assets/da3cde43-c00f-4e26-9639-7f32e091fbb5)
  6. Monitor the Configuration Process - In case for any errors, re-run the user data script which will be available in the
   **"C:\temp\userdata.ps1"**

  
## Description
- The following provisioning and configuration process is fully automated:
    - Provisioning:
      - EC2 Windows server allong with it's required resources
      - S3 Bucket for File upload/downlod - for Grafana
    - Configuration:
      - IIS server
      - Deploys a web app from [Sample App](https://github.com/AzureWorkshops/samples-simple-iis-website)
      - Exposes the Web APP to the <http:<Instance_PUB_IP>:8080> and localhost:8080
        ![image](https://github.com/user-attachments/assets/d43a65a1-052d-47fa-be64-2fd963675b24)
      - Ensures that IIS setup is ready to automatically deploy any .NET application in the future.
      - Generate a dump file of the deployed IIS webstie
      - Generates a usage Report provided in: html; csv and json
        ![image](https://github.com/user-attachments/assets/e46019c4-53fa-4758-af54-d50fc27d4051)

      - Installs Prometheos and Exposes server metrics at localhost:9090
        ![image](https://github.com/user-attachments/assets/77038dfc-7952-4319-ae96-00dc26c2fd9a)
        ![image](https://github.com/user-attachments/assets/ff036bff-884f-47e3-a720-afec06f78767)
        
      - Creates a Scheduled Task to be run every 5 minutes, that sents the metrics to an API Endpoint like Pipedream:         
        https://eofnzuh3c3qiljs.m.pipedream.net
        ![Screenshot 2024-12-27 054129](https://github.com/user-attachments/assets/34e029ec-8c6e-48fe-8cc8-97ef36c5f65b)
- The Project completes every asspect of the Interview Task:
- All the Executed Transcript is stored in "C:\temp" directory
   - Two files: windows-exporter.txt and userdata.txt
- All the scripts stored in the "C:\temp" directory
  ![image](https://github.com/user-attachments/assets/d5dce0ae-9721-47c7-b102-0449d60b74a7)
- The generated dump file is stored in "C:\temp"
- The Usage Report is stored in "C:\Users\Administrator\AppData\Local\Temp\2"
  Three Files: IISUsageReport.html; IISUsageReport.csv; IISUsageReport.json
  ![image](https://github.com/user-attachments/assets/f8be295c-728e-4fcd-b717-48be9971cda5)
  

## Pre-conditions
- [AWS Account](https://aws.amazon.com/resources/create-account/)
- [IAM Roles](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

## Contributing
Provide guidelines for contributing here.

## License
This project is licensed under the terms of the [LICENSE](https://github.com/Dan4ik7/Infigo/blob/main/LICENSE).
