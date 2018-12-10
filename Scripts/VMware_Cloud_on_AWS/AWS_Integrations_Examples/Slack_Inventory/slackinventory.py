"""

Basic Tests against the Skyscraper API
VMC API documentation available at https://vmc.vmware.com/swagger/index.html#/
CSP API documentation is available at https://saas.csp.vmware.com/csp/gateway/api-docs
vCenter API documentation is available at https://code.vmware.com/apis/191/vsphere-automation

Matt Dreyer
August 15, 2017

You can install python 3.6 from https://www.python.org/downloads/windows/

You can install the dependent python packages locally (handy for Lambda) with:
pip install requests -t . --upgrade
pip install simplejson -t . --upgrade
pip install certifi -t . --upgrade
pip install pyvim -t . --upgrade
pip install datetime -t . --upgrade

"""

import requests                         #need this for Get/Post/Delete
import simplejson as json               #need this for JSON
import datetime                         #need this for a time stamp

# To use this script you need to create an OAuth Refresh token for your Org
# You can generate an OAuth Refresh Token using the tool at vmc.vmware.com
# https://console.cloud.vmware.com/csp/gateway/portal/#/user/tokens
strAccessKey = "your key goes here"


#where are our service end points
strProdURL = "https://vmc.vmware.com"
strCSPProdURL = "https://console.cloud.vmware.com"
slackURL = "https://hooks.slack.com/services/T6Mrrrrr/B6TSrrrrr/RUldlEzzeY0Dy3drrrrrr"
  
#make a datestamp
rightnow = str(datetime.datetime.now())
rightnow = rightnow.split(".")[0] #get rid of miliseconds




def getAccessToken(myKey):
    params = {'refresh_token': myKey}
    headers = {'Content-Type': 'application/json'}
    response = requests.post('https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize', params=params, headers=headers)
    json_response = response.json()
    access_token = json_response['access_token']

    # debug only
#    print(response.status_code)
#    print(response.json())	    
    
    return access_token

    
	
#-------------------- Figure out which Org we are in
def getTenantID(sessiontoken):

    myHeader = {'csp-auth-token' : sessiontoken}

    response = requests.get( strProdURL + '/vmc/api/orgs', headers=myHeader)

# debug only
#    print(response.status_code)
#    print(response.json())	
	
# parse the response to grab our tenant id
    jsonResponse = response.json()
    strTenant = str(jsonResponse[0]['id'])
	
    return(strTenant)

    
#---------------Login to vCenter and get an API token
# this will only work if the MGW firewall rules are configured appropriately
def vCenterLogin(sddcID, tenantid, sessiontoken):

    #Get the vCenter details from VMC
    myHeader = {'csp-auth-token' : sessiontoken}
    myURL = strProdURL + "/vmc/api/orgs/" + tenantid + "/sddcs/" + sddcID
    response = requests.get(myURL, headers=myHeader)
    jsonResponse = response.json()

    vCenterURL = jsonResponse['resource_config']['vc_ip']
    vCenterUsername = jsonResponse['resource_config']['cloud_username']
    vCenterPassword = jsonResponse['resource_config']['cloud_password']

    
    #Now get an API token from vcenter
    myURL = vCenterURL + "rest/com/vmware/cis/session"
    response = requests.post(myURL, auth=(vCenterUsername,vCenterPassword))
    token = response.json()['value']
    vCenterAuthHeader = {'vmware-api-session-id':token}

    return(vCenterURL, vCenterAuthHeader)

	
 
 #------------ Get vCenter inventory and post to slack
def getSDDCInventory(sddcID, tenantid, sessiontoken):
 
    #first we need to get an authentication token from vCenter
    vCenterURL, vCenterAuthHeader = vCenterLogin(sddcID, tenantid, sessiontoken)

    #now let's get a VM count
    # for all vms use this : myURL = vCenterURL + "rest/vcenter/vm"
    # for management vms use this: myURL = vCenterURL + "rest/vcenter/vm?filter.resource_pools=resgroup-54"
    # for workload vms use this: myURL = vCenterURL + "rest/vcenter/vm?filter.resource_pools=resgroup-55"
    myURL = vCenterURL + "rest/vcenter/vm"
    response = requests.get(myURL, headers=vCenterAuthHeader)

    #deal with  vAPI wrapping
    vms = response.json()['value']

    poweredon = []
    poweredoff = []
    
    for i in vms:
        if i['power_state'] == "POWERED_ON":
            poweredon.append(i['name'])
        else:
            poweredoff.append(i['name'])
            
    vm_on = len(poweredon)
    vm_off = len(poweredoff)
    
    #next let's figure out how much space we have left on the datastore
    myURL = vCenterURL + "rest/vcenter/datastore"
    response = requests.get(myURL, headers=vCenterAuthHeader)    
    
    #grab the workload datastore
    datastore = response.json()['value'][1]
    ds_total = int(datastore['capacity'])
    ds_free = int(datastore['free_space'])
    
    usage = int((ds_free / ds_total) * 100)
    freeTB = ( ds_free / 1024 / 1024 / 1024 / 1024)
    
    
    jsonSlackMessage = {'text': \
        "SDDC Inventory Report\n" + \
        "\t " + str(vm_on) + " Virtual Machines Running\n" + \
        "\t " + str(vm_off) + " Virtual Machines Powered Off\n" + \
        "\t " + str(usage) + "% Datastore Capacity Remaining (" + str(int(freeTB)) + " TB)"}     
    
    postSlack(slackURL, jsonSlackMessage)
    
    return()
 
#------------------ Post something to Slack
# Slack API info can be found at https://api.slack.com/incoming-webhooks
# https://api.slack.com/tutorials/slack-apps-hello-world
# Need to create a new App using the Slack API App Builder -- it only needs to do one thing - catch a webhook 

def postSlack(slackURL, slackJSONData):

    slackData = json.dumps(slackJSONData)

    myHeader = {'Content-Type': 'application/json'}    
    response = requests.post(slackURL, slackData, headers=myHeader)
    
    if response.status_code != 200:
        raise ValueError(
            'Request to slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
        )
    
    return


 
    
#--------------------------------------------
#---------------- Main ----------------------
#--------------------------------------------
def lambda_handler(event, context):

    sddcID = " your id goes here"
    tenantID = "your tenant goes here"

	#Get our access token
    sessiontoken = getAccessToken(strAccessKey)

    #get the inventory and dump it to 
    getSDDCInventory(sddcID, tenantID, sessiontoken)
    
    return
    
#testing only
#lambda_handler(0, 0)