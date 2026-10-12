/* Forces FL Studio to repaint after the nested output is resized.
 *
 * When labwc resizes FL's window, FL's panels do re-lay-out -- the channel rack
 * moves to the new right edge correctly -- but the background between them is
 * never erased, so it is left black. Measured at 71.9% of a band across the
 * middle of a 1695x504 window, stable for as long as you leave it alone.
 *
 * It is specifically an erase problem, not a layout one. XClearArea with
 * exposures turns the black into white and FL still never draws there; a size
 * nudge, a WM unmaximize/remaximize and a pointer warp across the gap all leave
 * it at 71.9%. Asking Win32 for the erase directly is what works, and unlike
 * the minimise/restore this replaces, it never unmaps the window -- so there is
 * no black flash.
 */
#include <windows.h>
#include <string.h>

static BOOL CALLBACK pick(HWND hwnd, LPARAM lp) {
    char title[256];
    if (!IsWindowVisible(hwnd)) return TRUE;
    if (!GetWindowTextA(hwnd, title, sizeof title)) return TRUE;
    if (strncmp(title, "FL Studio", 9) != 0) return TRUE;
    RECT r;
    if (!GetWindowRect(hwnd, &r)) return TRUE;
    if (r.right - r.left < 400) return TRUE;
    *(HWND *)lp = hwnd;
    return TRUE;
}

int main(void) {
    HWND fl = NULL;
    EnumWindows(pick, (LPARAM)&fl);
    if (!fl) return 1;
    /* The panels re-lay-out on resize but the background between them is never
       erased, so ask for an erase and a synchronous full repaint. */
    RedrawWindow(fl, NULL, NULL,
                 RDW_INVALIDATE | RDW_ERASE | RDW_FRAME |
                 RDW_ALLCHILDREN | RDW_UPDATENOW | RDW_ERASENOW);
    return 0;
}
