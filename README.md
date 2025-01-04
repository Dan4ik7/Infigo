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
      

## Pre-conditions
- [AWS Account](https://aws.amazon.com/resources/create-account/)
- [IAM Roles](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

## Contributing
Provide guidelines for contributing here.

## License
This project is licensed under the terms of the [LICENSE](https://github.com/Dan4ik7/Infigo/blob/main/LICENSE).
