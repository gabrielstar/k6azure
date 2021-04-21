# K6 Template Repo for integration with Azure DevOps and Azure Workbooks

This template repo contains:

- sample script with convenient way of building requests with a RequestBuilder
- convenient way of describing endpoints
- sample test using scenarios, trends, groups
- workbook ARM template that allows to visualize k6 results in LogAnalytics, do A/B testing and trending
- script to upload data to LogAnalytics in JMeter format (so you can have both in the same project)
- ready to use Azure DevOps pipeline

How to make most of it?

## Run it locally first

1. Create a folder ${HOME}/projects to store your local test results. Open powershell console

    ```
     //Go to k6 and run
    .\k6.ps1

### Create a place to store and visualize your results in the cloud (optional)

1. Go to your LogAnalytics and store LogAnalytics id and SharedKey in ${HOME}/projects/workbooks.properties. See k6/workbooks/workbooks.properties for example of file.
2. Go to Azure Portal, Search -> Deploy Custom Template -> Paste JSON from k6/workbooks/workbooks.arm.template.statistics.detailed.json. Specify name of your own Log Analytics workspace while deploying Workbook.
3. in k6.ps1 set $SaveResultsToWorkbooks = $true
4. Run .\k6.ps1 and after few minutes you can enjoy your results in the Workbook (first run takes a while)

### Create DevOps pipeline (optional) and run everything from there

1. Create pipeline from k6/k6.yaml. Pipeline will use an existing k6 installation or install k6 as a package or docker container if docker is available.
2. If you want results to be saved to workbooks provide the following securely (e.g. as secrets from Library):

          
            -WorkbooksId 'ReplaceMe'
            -SharedKey 'ReplaceMe' 
 
You are ready to run your pipeline from Azure DevOps and check results in your workbooks.
Repo should be simple enough to modify :) Enjoy.


---

/tools contains scripts to upload results to workbooks in JMeter format, as I use both JMeter and k6 it allows me to browse both resul types in one place
That is why I normalize data but you can do whatever you please. 

