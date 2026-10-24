#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1200, 840);
  if (!window.Create(L"NOIR CHROME", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  // Place the window in the middle of the usable desktop, shrinking it if the
  // preferred size does not fit (small laptops, large display scaling).
  HWND hwnd = window.GetHandle();
  RECT work_area;
  if (::SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0)) {
    RECT rect;
    ::GetWindowRect(hwnd, &rect);
    const int work_width = work_area.right - work_area.left;
    const int work_height = work_area.bottom - work_area.top;
    int width = rect.right - rect.left;
    int height = rect.bottom - rect.top;
    width = std::min(width, work_width - 64);
    height = std::min(height, work_height - 64);
    const int x = work_area.left + (work_width - width) / 2;
    const int y = work_area.top + (work_height - height) / 2;
    ::SetWindowPos(hwnd, nullptr, x, y, width, height,
                   SWP_NOZORDER | SWP_NOACTIVATE);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
