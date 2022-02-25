*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Excel.Files
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url_from_user}=    Get Value From User    Input Url to Download CSV
    #https://robotsparebinindustries.com/orders.csv
    Download    ${url_from_user}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    Open the robot order website
    FOR    ${row}    IN    @{orders}
        Click Button    OK
        #uld Contain Radio Button    xpath://*[@id="id-body-1"]
        #Page Should Contain Radio Button    xpath://*[@id="id-body-2"]
        #Page Should Contain Radio Button    xpath://*[@id="id-body-3"]
        #Page Should Contain Radio Button    xpath://*[@id="id-body-4"]
        #Page Should Contain Radio Button    xpath://*[@id="id-body-5"]
        #Page Should Contain Radio Button    xpath://*[@id="id-body-6"]
        Fill the form    ${row}
        Preview Robot
        #Run Keyword And Continue On Failure    Submit order
        Wait Until Keyword Succeeds    10x    0.1 sec    Submit order
        #Submit order
        ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
        Html To Pdf    ${order_receipt_html}    ${OUTPUT_DIR}${/}${row}[Order number].pdf    overwrite=True
        Wait Until Page Contains Element    id:robot-preview-image
        Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${row}[Order number].PNG
        Embed Screenshot in PDF    ${row}
        Order another Robot
        #robot-preview-image
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[URL]
    #Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]    clear=True

Preview Robot
    Click Element    xpath://*[@id="root"]/div/div[1]/div/div[2]/div[1]/button
    Wait Until Element Is Visible    xpath://*[@id="model-info"]
    Click Button    id:preview
    Wait Until Page Contains Element    robot-preview-image

Submit order
    Click Element    xpath://*[@id="root"]/div/div[1]/div/div[2]/div[1]/button
    Click Button    order
    Wait Until Page Contains Element    receipt

Embed Screenshot in PDF
    [Arguments]    ${row}
    ${receipt_pdf}=    Open Pdf    ${OUTPUT_DIR}${/}${row}[Order number].pdf
    ${image_list}=    Create List    ${OUTPUT_DIR}${/}${row}[Order number].PNG
    Add Files To Pdf    ${image_list}    ${OUTPUT_DIR}${/}${row}[Order number].pdf    append:true
    Close Pdf    ${receipt_pdf}

Order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}    receipts.zip    include=*.pdf
