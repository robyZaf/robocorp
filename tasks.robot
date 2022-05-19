*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    #auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             RPA.RobotLogListener


*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         10x
${GLOBAL_RETRY_INTERVAL}=       2s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Documentation]    Returns the orders from CSV file
    # ${csv_order_link}=    Input from dialog
    ${csv_order_secre}=    Get Secret    csv_file_link
    Download    ${csv_order_secre}[link]    overwrite=true
    ${orders}=    Read table from CSV    orders.csv    header=true
    RETURN    ${orders}

Input from dialog
    # keyword used in order to take link for CSV file from user
    Add heading    Please enter link to CSV orders file
    Add text input    link
    ${result}=    Run dialog    height=320    width=480
    RETURN    ${result}[link]

Close the annoying modal
    Click Button When Visible    class:btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Confirm order

Confirm order
    # ${keywords_to_mute}=    Create List    ${Wait Until Page Contains    Thank you for your order!    2s}
    Click Button    order
    Mute Run On Failure    Wait Until Page Contains
    Wait Until Page Contains
    ...    Thank you for your order!
    ...    2s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${html_receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    Html To Pdf    ${html_receipt}    ${pdf_path}
    RETURN    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}screenshot${/}${order_number}.png
    Screenshot    id:robot-preview-image    ${screenshot_path}
    RETURN    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip
