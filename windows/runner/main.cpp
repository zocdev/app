#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <wtsapi32.h>

#include "flutter_window.h"
#include "utils.h"

// Procedimiento de ventana personalizado para manejar el evento de cerrar
static WNDPROC originalWndProc = nullptr;

static LRESULT CALLBACK CustomWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  if (msg == WM_CLOSE) {
    // Al hacer clic en "X", ocultar la ventana en lugar de cerrarla
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }
  // Para todos los demás mensajes, usar el procedimiento predeterminado
  return CallWindowProc(originalWndProc, hwnd, msg, wParam, lParam);
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  auto controller = std::make_unique<flutter::FlutterViewController>(510, 435, project);
  if (!controller->engine() || !controller->view()) {
    return EXIT_FAILURE;
  }

  FlutterWindow window(project);
  if (!window.CreateAndShow(L"zoc", Win32Window::Point(10, 10), Win32Window::Size(510, 435))) {
    return EXIT_FAILURE;
  }

  HWND hwnd = window.GetHandle();
  LONG style = ::GetWindowLong(hwnd, GWL_STYLE);
  style &= ~(WS_MAXIMIZEBOX | WS_SIZEBOX);
  ::SetWindowLong(hwnd, GWL_STYLE, style);
  window.SetQuitOnClose(false);

  // Configurar nuestro procedimiento de ventana personalizado
  originalWndProc = (WNDPROC)SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(CustomWndProc));

  MSG msg;
  while (GetMessage(&msg, nullptr, 0, 0)) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}