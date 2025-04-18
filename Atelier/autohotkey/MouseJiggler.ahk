; https://www.autohotkey.com/board/topic/95131-how-to-simulate-mouse-movements-every-5-minutes-without-actually-moving-them/
#SingleInstance force
waitMinutes := 5 ;Number of minutes to wait

Loop
{
    Sleep(waitMinutes * 60 * 1000)
    MouseMove(10, 0, 20, "R")
    MouseMove(-10, 0, 20, "R")
}
