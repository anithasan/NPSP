*** Settings ***

Resource       cumulusci/robotframework/Salesforce.robot
Library        DateTime
Library        NPSP.py

*** Variables ***
${task1}  Send Email1
${sub_task}    Welcome Email1-1
${task2}     Make a Phone Call2


*** Keywords ***

Capture Screenshot and Delete Records and Close Browser
    Run Keyword If Any Tests Failed      Capture Page Screenshot
    Close Browser
    Delete Session Records
    
API Create Contact
    [Arguments]      &{fields}
    ${first_name} =  Generate Random String
    ${last_name} =   Generate Random String
    ${contact_id} =  Salesforce Insert  Contact
    ...                  FirstName=${first_name}
    ...                  LastName=${last_name}
    ...                  &{fields}  
    &{contact} =     Salesforce Get  Contact  ${contact_id}
    [return]         &{contact}

API Modify Contact
    [Arguments]      ${contact_id}      &{fields}
    Salesforce Update       Contact     ${contact_id}
    ...                     &{fields}
    @{records} =  Salesforce Query      Contact
    ...              select=Id,FirstName,LastName,Email
    ...              Id=${contact_id}
    &{contact} =  Get From List  ${records}  0
    [return]         &{contact}

API Create Campaign
    [Arguments]      &{fields}
    ${name} =   Generate Random String
    ${campaign_id} =  Salesforce Insert  Campaign
    ...                  Name=${name}
    ...                  &{fields}  
    &{campaign} =     Salesforce Get  Campaign  ${campaign_id}
    [return]         &{campaign}
    
API Create Opportunity
    [Arguments]      ${account_id}    ${opp_type}      &{fields} 
    ${rt_id} =       Get Record Type Id  Opportunity  ${opp_type}
    ${close_date} =  Get Current Date  result_format=%Y-%m-%d
    ${opp_id} =  Salesforce Insert    Opportunity
    ...               AccountId=${account_id}
    ...               RecordTypeId=${rt_id}
    ...               StageName=Closed Won
    ...               CloseDate=${close_date}
    ...               Amount=100
    ...               Name=Test Donation
    ...               npe01__Do_Not_Automatically_Create_Payment__c=true 
    ...               &{fields}
    &{opportunity} =     Salesforce Get  Opportunity  ${opp_id} 
    [return]         &{opportunity}  
 
API Create Organization Account
    [Arguments]      &{fields}
    ${name} =        Generate Random String
    ${rt_id} =       Get Record Type Id  Account  Organization
    ${account_id} =  Salesforce Insert  Account
    ...                  Name=${name}
    ...                  RecordTypeId=${rt_id}
    ...                  &{fields}
    &{account} =     Salesforce Get  Account  ${account_id}
    [return]         &{account}

API Create Primary Affiliation
    [Arguments]      ${account_id}      ${contact_id}    &{fields}    
    ${opp_id} =  Salesforce Insert    npe5__Affiliation__c
    ...               npe5__Organization__c=${account_id}
    ...               npe5__Contact__c=${contact_id}
    ...               npe5__Primary__c=true 
    ...               &{fields}

API Create Secondary Affiliation
    [Arguments]      ${account_id}      ${contact_id}    &{fields}    
    ${opp_id} =  Salesforce Insert    npe5__Affiliation__c
    ...               npe5__Organization__c=${account_id}
    ...               npe5__Contact__c=${contact_id}
    ...               npe5__Primary__c=false 
    ...               &{fields}

API Create Relationship
    [Arguments]      ${contact_id}      ${relcontact_id}    ${relation}    &{fields}
    ${rel_id} =  Salesforce Insert  npe4__Relationship__c
    ...                  npe4__Contact__c=${contact_id}
    ...                  npe4__RelatedContact__c=${relcontact_id}
    ...                  npe4__Type__c=${relation}
    ...                  npe4__Status__c=Current    
    ...                  &{fields}  
    &{relation} =     Salesforce Get  npe4__Relationship__c  ${rel_id}
    [return]         &{relation}
    
     
# API Create Engagement Plan
    # [Arguments]      ${plan_name}     &{fields}    
    # ${opp_id} =  Salesforce Insert    npsp__Engagement_Plan_Template__c
    # ...               Name=${plan_name}
    # ...               npsp__Description__c=This plan is created via Automation 
    # ...               &{fields}

API Create Recurring Donation
    [Arguments]        &{fields}
    ${ns} =            Get Npsp Namespace Prefix
    ${recurring_id} =  Salesforce Insert  npe03__Recurring_Donation__c
    ...                &{fields} 
    &{recurringdonation} =           Salesforce Get     npe03__Recurring_Donation__c  ${recurring_id}
    [return]           &{recurringdonation}

API Query Installment
    [Arguments]        ${id}                      ${installment}    &{fields}
    @{object} =        Salesforce Query           Opportunity
    ...                select=Id
    ...                npe03__Recurring_Donation__c=${id}
    ...                ${ns}Recurring_Donation_Installment_Name__c=${installment}
    ...                &{fields}
    [return]           @{object}

API Create GAU
    [Arguments]      &{fields}
    ${name} =   Generate Random String
    ${ns} =    Get Npsp Namespace Prefix
    ${gau_id} =  Salesforce Insert  ${ns}General_Accounting_Unit__c
    ...               Name=${name}
    ...               &{fields} 
    &{gau} =     Salesforce Get  ${ns}General_Accounting_Unit__c  ${gau_id}
    [return]         &{gau}  

API Create DataImportBatch
    [Arguments]      &{fields}
    ${name} =   Generate Random String
    ${ns} =  Get NPSP Namespace Prefix
    ${batch_id} =  Salesforce Insert  ${ns}DataImportBatch__c
    ...                  Name=${name}
    ...                  &{fields}
    &{batch} =     Salesforce Get  ${ns}DataImportBatch__c  ${batch_id}
    [return]         &{batch}
    
API Create DataImport   
    [Arguments]      &{fields}
    ${ns} =  Get NPSP Namespace Prefix
    ${dataimport_id} =  Salesforce Insert  ${ns}DataImport__c
    ...                  &{fields}
    &{data_import} =     Salesforce Get  ${ns}DataImport__c  ${dataimport_id}
    [return]         &{data_import} 

New Contact for HouseHold
    Click Related List Button  Contacts    New 
    Wait Until Modal Is Open
    ${first_name} =           Generate Random String
    ${last_name} =            Generate Random String
    Populate Form
    ...                       First Name=${first_name}
    ...                       Last Name=${last_name}
    Click Modal Button        Save    
    Wait Until Modal Is Closed
    Go To Object Home         Contact
    Click Link                link= ${first_name} ${last_name}
    Wait Until Location Contains    /view
    ${contact_id} =           Save Current Record ID For Deletion      Contact
    [return]                  ${contact_id} 
        

Create Primary Affiliation
    [Arguments]      ${acc_name}      ${con_id}
    Go To Record Home  ${con_id}
    # To make sure the field we want to edit has rendered
    # and is not obscured by the footer, scroll to one further down
    Scroll Element Into View  text:Description
    Click Button  title:Edit Primary Affiliation
    Wait For Locator  record.edit_form
    Populate Lookup Field    Primary Affiliation    ${acc_name}
    Click Record Button    Save 

Create Secondary Affiliation
    [Arguments]      ${acc_name}      ${con_id}
    Go To Record Home  ${con_id}
    Select Tab  Related
    Click Related List Button   Organization Affiliations    New
    Populate Lookup Field    Organization    ${acc_name}
    Click Modal Button    Save
    
Create Opportunities
    [Arguments]    ${opp_name}    ${hh_name}    ${stage}
    Populate Form
    ...                       Opportunity Name= ${opp_name}
    ...                       Amount=100 
    Select Value From Dropdown    Stage    ${stage}
    Populate Lookup Field    Account Name    ${hh_name}
    Open Date Picker    Close Date
    Pick Date    Today
    Select Lightning Checkbox    Do Not Automatically Create Payment
    Click Modal Button        Save

Create Engagement Plan
    ${plan_name} =     Generate Random String
    Select App Launcher Tab  Engagement Plan Templates
    Click Special Object Button       New
    Wait For Locator    frame    Manage Engagement Plan Template
    # Choose Frame    Manage Engagement Plan Template
    # Wait For Locator    id    idName
    Select Frame And Click Element    Manage Engagement Plan Template    id    idName
    Enter Eng Plan Values    idName    ${plan_name}
    Enter Eng Plan Values    idDesc    This plan is created via Automation  
    Click Button    Add Task
    Wait Until Page Contains  Task 1
    Enter Task Id and Subject    Task 1    ${task1}
    Click Task Button    1    Add Dependent Task
    Enter Task Id and Subject    Task 1-1    ${sub_task}
    Click Button    Add Task
    Wait Until Page Contains  Task 2
    Enter Task Id and Subject    Task 2    ${task2}
    Page Scroll To Locator    button    Save
    Run Accessibility Check
    Click Button    Save
    Wait Until Location Contains    /view
    ${ns} =  Get NPSP Namespace Prefix
    Save Current Record ID For Deletion    ${ns}Engagement_Plan_Template__c
    [Return]    ${plan_name}    ${task1}    ${sub_task}     ${task2}
    
Create Level
    ${level_name}=    Generate Random String
    Select App Launcher Tab  Levels
    Click Special Object Button       New
    Choose Frame    Levels
    Enter Level Values
    ...            Level Name=${level_name}
    ...            Minimum Amount=0.1
    ...            Maximum Amount=0.9
    Enter Level Dd Values    Target    Contact
    Enter Level Dd Values    Source Field    Total Gifts
    Enter Level Dd Values    Level Field    Level
    Enter Level Dd Values    Previous Level Field    Previous Level
    Set Focus To Element   xpath: //input[@value='Save']
    Click Button  Save
    Unselect Frame
    Wait For Locator  obj-header  Level
    ${level_id} =   Save Current Record ID For Deletion  Level__c  
    [Return]    ${level_id}  ${level_name}

Verify Engagement Plan
    [Arguments]       ${plan_name}     @{others}
    Select App Launcher Tab  Engagement Plan Templates
    Click Link    link=${plan_name}
    Check Field Value    Engagement Plan Template Name    ${plan_name}
    Select Tab    Related
    Check Related List Values    Engagement Plan Tasks      @{others}

Create GAU
    ${gau_name} =         Generate Random String
    Select App Launcher Tab    General Accounting Units
    Click Object Button       New
    Populate Form
    ...                    General Accounting Unit Name=${gau_name}
    ...                    Largest Allocation=5
    Click Modal Button        Save
    #Sleep    2
    [Return]           ${gau_name}    

Run Donations Batch Process
    Open NPSP Settings  Bulk Data Processes  Rollup Donations Batch
    Click Settings Button    idPanelOppBatch    Run Batch
    # Wait For Locator    npsp_settings.status    CRLP_Account_SoftCredit_BATCH    Completed
    # Wait For Locator    npsp_settings.status    CRLP_RD_BATCH    Completed
    # Wait For Locator    npsp_settings.status    CRLP_Account_AccSoftCredit_BATCH    Completed
    # Wait For Locator    npsp_settings.status    CRLP_Contact_SoftCredit_BATCH    Completed
    # Wait For Locator    npsp_settings.status    CRLP_Account_BATCH    Completed
    # Wait For Locator    npsp_settings.status    CRLP_Contact_BATCH    Completed
    Wait For Locator    npsp_settings.status    RLLP_OppAccRollup_BATCH    Completed
    Wait For Locator    npsp_settings.status    RLLP_OppContactRollup_BATCH    Completed
    Wait For Locator    npsp_settings.status    RLLP_OppHouseholdRollup_BATCH    Completed
    Wait For Locator    npsp_settings.status    RLLP_OppSoftCreditRollup_BATCH    Completed
     
Scroll Page To Location
    [Arguments]    ${x_location}    ${y_location}
    Execute JavaScript    window.scrollTo(${x_location},${y_location}) 

Open NPSP Settings
    [Arguments]    ${topmenu}    ${submenu}
    Select App Launcher Tab      NPSP Settings
    Wait For Locator    frame    Nonprofit Success Pack Settings
    Choose Frame    Nonprofit Success Pack Settings
    Wait Until Element Is Visible  text:${topmenu}
    # Click Link With Text    text=${topmenu}
    Click Element With Locator    npsp_settings.side_panel    idPanelBulkProcesses
    Wait Until Element Is Visible  text:${submenu}
    Click Link With Text    text=${submenu}
    Sleep  1
    
Click Data Import Button
    [Arguments]       ${frame_name}    ${ele_path}     @{others}
    Select Frame And Click Element    ${frame_name}    ${ele_path}     @{others}
    
Click Field And Select Date
    [Arguments]    ${field}    ${date}
    Click Element With Locator    bge.field-input    ${field}    
    Click BGE Button    ${date}    
    
Run Accessibility Check
    Inject Axe Core Library
    &{results}    Get Axe Analysis Results
    Log Summary Of Results    ${results}
    Warn On Incomplete Rules    ${results}
    Warn On Violations Rules    ${results}    
      
     
Process Data Import Batch
    [Documentation]        Go to NPSP Data Import Page and change view to 'To be Imported' and Process Batch
    ...                    | status | expected status of batch processing Ex:'Completed' 'Errors' |
    [Arguments]    ${status}
    Go To Page                                         Listing                 DataImport__c
    Change View To                                     To Be Imported
    Click                                              Start Data Import
    Begin Data Import Process And Verify Status        BDI_DataImport_BATCH    ${status}
    Click Close Button    
