Attribute VB_Name = "OutlookModule"

' ================================================================
' MS Outlook Module for Visual Basic for Application
' ================================================================
'
' Author:       Julio L. Muller
' Version:      1.0.0
' Repository:   https://github.com/juliolmuller/VBA-Module-Outlook
'
' ================================================================

Option Private Module
Option Explicit

'Present the options of email text encoding to be used as parameter for functions
Public Enum EmailTextFormat
    PLAIN_TEXT = 1
    HTML = 2
    RICH_TEXT = 3
End Enum

'Switch Outlook to work online/offline.
Public Sub SetOutlookConnection(isOnline As Boolean)

    'Dimension local variables
    Dim objOutlookApp As Object
    Dim intOutlookStatus As Integer

    'Create Oulook object
    Set objOutlookApp = CreateObject("Outlook.Application")
    intOutlookStatus = objOutlookApp.GetNamespace("MAPI").ExchangeConnectionMode

    'Toggle Outlook to online/offline (Ribbon: "SEND/RECEIVE" > "Work Offline")
    If (isOnline) Then
        If (intOutlookStatus = 200) Then
            objOutlookApp.GetNamespace("MAPI").Folders.GetFirst.GetExplorer.CommandBars.ExecuteMso ("ToggleOnline")
        End If
    Else
        If (intOutlookStatus > 200) Then
            objOutlookApp.GetNamespace("MAPI").Folders.GetFirst.GetExplorer.CommandBars.ExecuteMso ("ToggleOnline")
        End If
    End If

End Sub

'Returns the user signature
Public Function GetOutlookSignature(signatureName As String) As String

    'Dimension local variables
    Dim strSignatureFilePath As String
    Dim strSignature As String

    'Get signature full file name
    strSignatureFilePath = "C:\Users\" & Environ("UserName") & "\AppData\Roaming\Microsoft\Signatures\" & signatureName & ".htm"
    On Error GoTo ErrorHandler_FileNotFound
    strSignature = GetFileContent(strSignatureFilePath)

    'Returns the file content
    GetOutlookSignature = strSignature
    Exit Function

'Returns nothing when signature is not found
ErrorHandler_FileNotFound:
    GetOutlookSignature = vbNullString

End Function

'Send email via Outlook
Public Function SendEmail(sendAfterwards As Boolean, subject As String, emailBody As String, msgFormat As EmailTextFormat, Optional toContacts As Variant, Optional ccContacts As Variant, Optional bccContacts As Variant, Optional attachments As Variant, Optional otherSenderAddress As String) As Boolean

    'Dimension local variables
    Dim objOutlookApp As Object
    Dim intVarType As Integer
    Dim strTo As String
    Dim strCC As String
    Dim strBCC As String
    Dim i As Integer

    'Convert email addresses to single string
    strTo = GroupContacts(toContacts)
    strCC = GroupContacts(ccContacts)
    strBCC = GroupContacts(bccContacts)

    'Validate essential information
    If (sendAfterwards And IsEmpty(strTo & strCC & strBCC)) Then
        sendAfterwards = False
    End If

    'Set up Outlook object
    Set objOutlookApp = CreateObject("Outlook.Application")

    'Open Outlook item and put information
    With objOutlookApp.CreateItem(0)
        If Not (IsEmpty(Trim(otherSenderAddress))) Then
            .SentOnBehalfOfName = otherSenderAddress
        End If
        .To = strTo
        .CC = strCC
        .BCC = strBCC
        .subject = subject
        .HTMLBody = emailBody
        .BodyFormat = msgFormat
        If (VarType(attachments) = 8192) Then
            For i = LBound(attachments) To UBound(attachments)
                .attachments.Add (attachments(i))
            Next i
        End If
        .Display
        If (sendAfterwards) Then
            '.Send
            SendKeys ("%S") 'Send email by typing "Alt + S"
        End If
    End With

    'Returns success
    SendEmail = True

End Function

'Returns the HTML text equivalent to a range
Public Function ConvertRangeToHTML(rngTarget As Range) As String

    'Dimension local variables
    Dim strTempFilePath As String
    Dim wbkTemp As Workbook

    'Create a new temporary workbook and copy only the target data to it
    strTempFilePath = Environ$("temp") & "\" & Format(Now, "dd-mm-yy h-mm-ss") & ".htm"
    rngTarget.Copy
    Set wbkTemp = Workbooks.Add(1)
    With wbkTemp.Sheets(1)
        .Cells(1).PasteSpecial Paste:=8
        .Cells(1).PasteSpecial xlPasteValues, , False, False
        .Cells(1).PasteSpecial xlPasteFormats, , False, False
        .Cells(1).Select
        Application.CutCopyMode = False
        On Error Resume Next
        .DrawingObjects.Visible = True
        .DrawingObjects.Delete
        On Error GoTo 0
    End With

    'Save temporary workbook as HTML file
    With wbkTemp.PublishObjects.Add( _
         SourceType:=xlSourceRange, _
         fileName:=strTempFilePath, _
         Sheet:=wbkTemp.Sheets(1).Name, _
         Source:=wbkTemp.Sheets(1).UsedRange.Address, _
         HtmlType:=xlHtmlStatic)
        .Publish (True)
    End With

    'Copy HTML file content to text/string variable (function return)
    ConvertRangeToHTML = Replace(GetStringFromHTML(strTempFilePath), "align=center x:publishsource=", "align=left x:publishsource=")
    
    'Close temporary files and delete them
    wbkTemp.Close SaveChanges:=False
    Kill strTempFilePath

End Function

'Returns the email addresses concatenated for input in the Outlook receipt fields
Private Function GroupContacts(varEmailAddresses As Variant) As String

    'Dimension local variables
    Dim strEmailConcat As String
    Dim intVarType As Integer
    Dim i As Integer

    'Convert array of email addresses to a single string
    intVarType = VarType(varEmailAddresses)
    If (intVarType = 8) Then
        strEmailConcat = varEmailAddresses
    ElseIf (intVarType > 8000) Then
        For i = LBound(varEmailAddresses) To UBound(varEmailAddresses)
            strEmailConcat = strEmailConcat & Trim(varEmailAddresses(i)) & "; "
        Next i
    Else
        strEmailConcat = Empty
    End If

    'Return result
    GroupContacts = strEmailConcat

End Function

'Returns the content of a file
Private Function GetFileContent(fullFileName As String) As String

    'Dimension local varable
    Dim fileIndex As Integer

    'Determine the next file number available for use by the FileOpen function and open it
    fileIndex = FreeFile
    Open fullFileName For Input As fileIndex

    'Capture file content
    GetFileContent = Input(LOF(fileIndex), fileIndex)

    'Close text fFile
    Close fileIndex

End Function
