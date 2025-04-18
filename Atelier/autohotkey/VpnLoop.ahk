#SingleInstance force

; Constants
; hours * minutes * seconds + milliseconds
refreshIntervalMilliseconds := 11 * 60 * 60 * 1000
Title := "Cisco Secure Client"

Loop
{
    Sleep(refreshIntervalMilliseconds * 60 * 1000)

    Run "C:\Program Files (x86)\Cisco\Cisco Secure Client\UI\csc_ui.exe"

    Sleep(2 * 1000)

    if WinExist(Title)
        WinActivate(Title)
        if WinWait(Title, "Disconnect" , 3)
            ControlClick("Button1", Title, "Disconnect")

        Sleep(12 * 1000)

        ; Click the same button which now says connect
        WinActivate(Title)
        if WinWait(Title, "Connect" , 20)
            ControlClick("Button1", Title, "Connect")

        Sleep(2 * 1000)

        ; Now click the 'Connect Anyway' button
        WinActivate(Title)
        if WinWait(Title, "Connect Anyway" , 20)
            ControlClick("Button2", Title, "Connect Anyway")
}
