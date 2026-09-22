# Graph Report - zoc1  (2026-09-18)

## Corpus Check
- 170 files · ~66,489 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 70 file(s) not represented in the graph (top: (none) 10, .xml 9, .plist 8)

## Summary
- 2530 nodes · 3369 edges · 191 communities (119 shown, 63 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a5b4414a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_state.dart
- flutter_flow_util.dart
- flutter_flow_theme.dart
- nav.dart
- flutter_flow_data_table.dart
- _/api_manager.dart
- flutter_flow_drop_down.dart
- package:flutter/material.dart
- ativities_struct.dart
- GeneratedPluginRegistrant.swift
- secure_storage_service.dart
- runner/my_application.cc
- main.dart
- flutter_flow_widgets.dart
- database.dart
- api_calls.dart
- expediente_model.dart
- error_handler.dart
- popup_dialog_model.dart
- flutter_flow_model.dart
- organization_users.dart
- FFAppState
- mensaje_antes_expediente_widget.dart
- auth_models.dart
- task_done_struct.dart
- table.dart
- flutter_flow_icon_button.dart
- data_saved_struct.dart
- internationalization.dart
- app_updater.dart
- users.dart
- verify_token_widget.dart
- custom_auth_manager.dart
- logout_widget.dart
- info_widget.dart
- int get
- user_struct.dart
- recover_password_widget.dart
- popup_dialog_widget.dart
- serialization_util.dart
- projects.dart
- Zoc
- lib/index.dart
- expediente_widget.dart
- email_enviado_widget.dart
- info_model.dart
- project_option_struct.dart
- task_option_struct.dart
- verify_email_struct.dart
- String get
- SupabaseDataRow
- orgs.dart
- redefinir_senha_widget.dart
- FlutterWindow
- conf_email_widget.dart
- recover_password_model.dart
- win32_window.cpp
- login_widget.dart
- confirma_logout_widget.dart
- dart:io
- uploaded_file.dart
- option_struct.dart
- user_data_struct.dart
- clients.dart
- generate_p_d_f.dart
- custom_functions.dart
- logout_confirmado_widget.dart
- sqlite_manager.dart
- DateTime?
- entrar_con_senha_widget.dart
- final_registration_widget.dart
- senha_alterada_widget.dart
- Win32Window
- entrar_con_senha_model.dart
- structs/index.dart
- time_entries.dart
- redefinir_senha_model.dart
- wWinMain
- heartbeats.dart
- tasks.dart
- login_model.dart
- package:google_fonts/google_fonts.dart
- verify_token_model.dart
- auth_session.dart
- bool get
- NotificationService
- BaseStruct
- heartbeat_logs.dart
- team_users.dart
- teams.dart
- user_projects.dart
- package:flutter/foundation.dart
- ../database.dart
- init.dart
- project_teams.dart
- role_permissions.dart
- roles.dart
- user_clients.dart
- user_tasks.dart
- instant_timer.dart
- package:flutter_test/flutter_test.dart
- MessageHandler
- custom_auth_user_provider.dart
- dart:convert
- compress_screenshot.dart
- DateTime get
- capture_screenshot_web.dart
- FFLocalizations
- schema_util.dart
- handle_new_rx_page
- Map
- actions/index.dart
- Iterable
- /backend/api_requests/api_calls.dart
- api_requests/api_manager.dart
- RegisterPlugins
- Point
- Size
- MainActivity.kt
- GoRouter
- TextStyle
- capture_screenshot_stub.dart
- AppStateNotifier
- Color
- FlutterFlowDataTableController
- ApiCallOptions
- GoRouterState
- Package.swift
- LaunchImage.imageset/README.md
- update_config.dart
- FlutterFlowTheme
- ThemeTypography
- safePop
- capture_screenshot_stub.dart
- _accessToken
- alwaysAllowBody
- _apiCache
- ApiCallOptions
- ApiCallResponse
- ApiCallType
- ApiManager
- apiUrl
- asQueryParams
- body
- bodyText
- BodyType
- cache
- call
- callName
- callType
- clearCache
- clone
- _cloneMap
- copyWith
- createBody
- decodeUtf8
- encodeBodyUtf8
- exception
- exceptionMessage
- fromCloudCallResponse
- fromHttpResponse
- getHeader
- _getMediaType
- headers
- _instance
- isStreamingApi
- jsonBody
- makeApiCall
- multipartRequest
- params
- props
- requestWithBody
- response
- returnBody
- statusCode
- streamedResponse
- succeeded
- toStringMap
- urlRequest
- getStreamedResponse
- bool?
- String?

## God Nodes (most connected - your core abstractions)
1. `FFAppState` - 29 edges
2. `Win32Window` - 23 edges
3. `SupabaseDataRow` - 22 edges
4. `SupabaseTable` - 22 edges
5. `FlutterFlowModel` - 19 edges
6. `T` - 12 edges
7. `Zoc` - 12 edges
8. `BaseStruct` - 11 edges
9. `MessageHandler` - 11 edges
10. `FlutterWindow` - 10 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `build` --references--> `FFAppState`  [EXTRACTED]
  lib/conf_email/conf_email_widget.dart → lib/app_state.dart
- `_ConfEmailWidgetState` --references--> `FFAppState`  [EXTRACTED]
  lib/conf_email/conf_email_widget.dart → lib/app_state.dart

## Import Cycles
- None detected.

## Communities (191 total, 63 thin omitted)

### Community 0 - "app_state.dart"
Cohesion: 0.02
Nodes (90): AppError? get, _activitie, addToActivitie, addToAtividadesFeitas, addToClientsOptions, addToDataSave, addToPdfBytes, addToProjectOptions (+82 more)

### Community 1 - "flutter_flow_util.dart"
Cohesion: 0.02
Nodes (87): ../app_state.dart, Brightness?, flutter_flow_model.dart, internationalization.dart, addToEnd, addToStart, applyAlpha, around (+79 more)

### Community 2 - "flutter_flow_theme.dart"
Cohesion: 0.02
Nodes (84): Color get, accent1, accent2, accent3, accent4, alternate, bodyLarge, bodyLargeFamily (+76 more)

### Community 3 - "nav.dart"
Cohesion: 0.03
Nodes (60): Alignment?, AppStateNotifier get, alignment, allParams, appDefault, appNavigatorKey, appState, clearRedirectLocation (+52 more)

### Community 4 - "flutter_flow_data_table.dart"
Cohesion: 0.03
Nodes (59): ColumnsBuilder, dart:math, DataRowBuilder, flutter_flow_util.dart, addHorizontalDivider, addTopAndBottomDivider, addVerticalDivider, borderRadius (+51 more)

### Community 5 - "_/api_manager.dart"
Cohesion: 0.04
Nodes (56): ApiCallType, BodyType?, dart:core, get_streamed_response.dart, _accessToken, alwaysAllowBody, _apiCache, ApiCallResponse (+48 more)

### Community 6 - "flutter_flow_drop_down.dart"
Cohesion: 0.04
Nodes (50): EdgeInsetsGeometry get, form_field_controller.dart, borderColor, borderRadius, borderWidth, build, _buildDropdown, _buildDropdownWidget (+42 more)

### Community 7 - "package:flutter/material.dart"
Cohesion: 0.05
Nodes (40): conf_email_widget.dart, confirma_logout_widget.dart, email_enviado_widget.dart, final_registration_widget.dart, /flutter_flow/flutter_flow_util.dart, /index.dart, createTasksStruct, fromMap (+32 more)

### Community 8 - "ativities_struct.dart"
Cohesion: 0.05
Nodes (44): api_client_exception.dart, /backend/api_requests/api_manager.dart, error_handler.dart, _ativities, createAtivitiesStruct, _finishTime, fromMap, fromSerializableMap (+36 more)

### Community 9 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (37): Any, app_links, audio_session, bitsdojo_window_macos, Cocoa, file_saver, Flutter, FlutterAppDelegate (+29 more)

### Community 10 - "secure_storage_service.dart"
Cohesion: 0.04
Nodes (45): Box?, cause, clear, closeStorage, containsKey, _ensureInitialized, error, _executeWithRetry (+37 more)

### Community 11 - "runner/my_application.cc"
Cohesion: 0.06
Nodes (38): FlPluginRegistry, FlView, fl_register_plugins(), main(), GApplication, gboolean, gchar, GObject (+30 more)

### Community 12 - "main.dart"
Cohesion: 0.05
Nodes (41): auth/auth_session.dart, auth/custom_auth/custom_auth_user_provider.dart, /desktop/update_dialog.dart, flutter_flow/internationalization.dart, GlobalKey, appState, _appStateNotifier, build (+33 more)

### Community 13 - "flutter_flow_widgets.dart"
Cohesion: 0.05
Nodes (41): BorderRadius?, BorderSide?, EdgeInsetsGeometry?, FaIconData?, IconAlignment?, borderRadius, borderSide, build (+33 more)

### Community 14 - "database.dart"
Cohesion: 0.05
Nodes (38): /backend/supabase/supabase.dart, database/database.dart, ../../../flutter_flow/lat_lng.dart, client, initialize, _instance, _kSupabaseAnonKey, _kSupabaseUrl (+30 more)

### Community 15 - "api_calls.dart"
Cohesion: 0.05
Nodes (38): api_config.dart, api_manager.dart, auth_models.dart, accessToken, AddAtivitiesCall, ApiPagingParams, authError, call (+30 more)

### Community 16 - "expediente_model.dart"
Cohesion: 0.05
Nodes (36): expediente_widget.dart, int?, buttonDownload, datePicked1, datePicked2, day, dispose, endDate (+28 more)

### Community 17 - "error_handler.dart"
Cohesion: 0.05
Nodes (36): _addToHistory, AppError, clearHistory, displayMessage, ErrorHandler, _errorHistory, ErrorType, fromApiResponse (+28 more)

### Community 18 - "popup_dialog_model.dart"
Cohesion: 0.06
Nodes (34): AudioPlayer?, activities, addToSelectedAtivitieLabel, addToSelectedAtivities, apiResult4ww, clientDropDownValue, clientDropDownValueController, dispose (+26 more)

### Community 19 - "flutter_flow_model.dart"
Cohesion: 0.06
Nodes (31): BuildContext, BuildContext? get, _activeKeys, _childrenIndexes, _childrenModels, _context, dispose, disposeOnWidgetDisposal (+23 more)

### Community 20 - "organization_users.dart"
Cohesion: 0.07
Nodes (30): authId, avatar, cnpj, cpf, createdAt, createRow, currency, dataField (+22 more)

### Community 21 - "FFAppState"
Cohesion: 0.08
Nodes (29): FFAppState, build, build, _resendEmail, build, build, build, build (+21 more)

### Community 22 - "mensaje_antes_expediente_widget.dart"
Cohesion: 0.09
Nodes (25): alerta_encerrar_sesion_model.dart, alerta_encerrar_sesion_widget.dart, class, /flutter_flow/flutter_flow_theme.dart, MensajeAntesExpedienteModel, createState, dispose, initState (+17 more)

### Community 23 - "auth_models.dart"
Cohesion: 0.07
Nodes (27): AuthError, code, ConfirmEmailRequest, email, emailNotVerified, error, exists, firstName (+19 more)

### Community 24 - "task_done_struct.dart"
Cohesion: 0.07
Nodes (26): double get, createTaskDoneStruct, _endDate, fromMap, fromSerializableMap, hasEndDate, hashCode, hasHours (+18 more)

### Community 25 - "table.dart"
Cohesion: 0.07
Nodes (26): containsOrNull, createRow, delete, eqOrNull, gteOrNull, gtOrNull, inFilterOrNull, insert (+18 more)

### Community 26 - "flutter_flow_icon_button.dart"
Cohesion: 0.08
Nodes (26): borderColor, borderRadius, borderWidth, build, buttonSize, createState, didUpdateWidget, disabledColor (+18 more)

### Community 27 - "data_saved_struct.dart"
Cohesion: 0.08
Nodes (25): createDataSavedStruct, fromMap, fromSerializableMap, hashCode, hasProject, hasProjectId, hasRemote, hasTask (+17 more)

### Community 28 - "internationalization.dart"
Cohesion: 0.08
Nodes (25): createLocale, getStoredLocale, getText, getVariableText, initialize, isSupported, _isSupportedLocale, _kLocaleStorageKey (+17 more)

### Community 29 - "app_updater.dart"
Cohesion: 0.08
Nodes (23): 4
done
sleep, @visibleForTesting, 1, _applyMacos, _applyWindows, AppUpdater, checkForUpdate, downloadAndApply (+15 more)

### Community 30 - "users.dart"
Cohesion: 0.09
Nodes (23): authId, avatar, cnpj, cpf, createdAt, createRow, dataField, email (+15 more)

### Community 31 - "verify_token_widget.dart"
Cohesion: 0.09
Nodes (23): VerifyTokenModel, _buildOtpBox, _canResend, _clearOtp, createState, dispose, initState, _invalidOtpMessage (+15 more)

### Community 32 - "custom_auth_manager.dart"
Cohesion: 0.09
Nodes (22): custom_auth_user_provider.dart, authenticationToken, currentUser, CustomAuthManager, ensureValidSession, initialize, _kAuthTokenKey, _kRefreshTokenKey (+14 more)

### Community 33 - "logout_widget.dart"
Cohesion: 0.10
Nodes (21): /desktop/popup_window.dart, /flutter_flow/flutter_flow_icon_button.dart, /flutter_flow/instant_timer.dart, apiResult4ww, dispose, FirstTimer, initState, LogoutModel (+13 more)

### Community 34 - "info_widget.dart"
Cohesion: 0.09
Nodes (21): info_model.dart, isDesktopWindow, _isHiddenOrMinimized, isMinimized, kDesktopPopupWindowSize, kDesktopWindowSize, prepareDesktopWindowForPopup, restoreDesktopWindowAfterPopup (+13 more)

### Community 35 - "int get"
Cohesion: 0.10
Nodes (20): int get, lat_lng.dart, hashCode, latitude, LatLng, longitude, operator, serialize (+12 more)

### Community 36 - "user_struct.dart"
Cohesion: 0.09
Nodes (21): _avatar, createUserStruct, _email, _firstName, fromMap, fromSerializableMap, hasAvatar, hasEmail (+13 more)

### Community 37 - "recover_password_widget.dart"
Cohesion: 0.10
Nodes (21): FlutterFlowDataTable, _FlutterFlowDataTableState, FlutterFlowModel, StatefulWidgetExtensions, RecoverPasswordModel, createState, dispose, _fieldDecoration (+13 more)

### Community 38 - "popup_dialog_widget.dart"
Cohesion: 0.10
Nodes (20): Duration, /flutter_flow/custom_functions.dart, /flutter_flow/flutter_flow_drop_down.dart, /flutter_flow/form_field_controller.dart, PopupDialogModel, createState, dispose, ignoreAfter (+12 more)

### Community 39 - "serialization_util.dart"
Cohesion: 0.11
Nodes (18): /backend/sqlite/queries/sqlite_row.dart, ../../flutter_flow/place.dart, ../../flutter_flow/uploaded_file.dart, data, dateTimeRangeFromString, dateTimeRangeToString, endStr, isList (+10 more)

### Community 40 - "projects.dart"
Cohesion: 0.12
Nodes (17): avatar, billable, budget, clientId, createdAt, createRow, description, end (+9 more)

### Community 41 - "Zoc"
Cohesion: 0.11
Nodes (17): API, Auth & session flow, Build, Configuration notes, Development, Features, Getting started, Main endpoints (+9 more)

### Community 42 - "lib/index.dart"
Cohesion: 0.12
Nodes (15): /conf_email/conf_email_widget.dart, /confirma_logout/confirma_logout_widget.dart, /email_enviado/email_enviado_widget.dart, /entrar_con_senha/entrar_con_senha_widget.dart, /expediente/expediente_widget.dart, /final_registration/final_registration_widget.dart, /info/info_widget.dart, /login/login_widget.dart (+7 more)

### Community 43 - "expediente_widget.dart"
Cohesion: 0.14
Nodes (15): /custom_code/actions/index.dart, expediente_model.dart, /flutter_flow/flutter_flow_data_table.dart, ExpedienteModel, createState, dispose, ExpedienteWidget, _ExpedienteWidgetState (+7 more)

### Community 44 - "email_enviado_widget.dart"
Cohesion: 0.14
Nodes (15): email_enviado_model.dart, EmailEnviadoModel, _canResend, createState, dispose, EmailEnviadoWidget, _EmailEnviadoWidgetState, initState (+7 more)

### Community 45 - "info_model.dart"
Cohesion: 0.12
Nodes (15): info_widget.dart, dispose, emailFocusNode1, emailFocusNode2, emailTextController1, emailTextController2, formKey, initState (+7 more)

### Community 46 - "project_option_struct.dart"
Cohesion: 0.12
Nodes (15): _clientId, createProjectOptionStruct, fromMap, fromSerializableMap, hasClientId, hashCode, hasId, hasName (+7 more)

### Community 47 - "task_option_struct.dart"
Cohesion: 0.12
Nodes (15): createTaskOptionStruct, fromMap, fromSerializableMap, hashCode, hasId, hasName, hasProjectId, _id (+7 more)

### Community 48 - "verify_email_struct.dart"
Cohesion: 0.12
Nodes (15): createVerifyEmailStruct, _exists, _firstTime, fromMap, fromSerializableMap, hasExists, hasFirstTime, hashCode (+7 more)

### Community 49 - "String get"
Cohesion: 0.13
Nodes (14): data, hashCode, operator, table, tableName, toString, createRow, description (+6 more)

### Community 50 - "SupabaseDataRow"
Cohesion: 0.15
Nodes (15): SupabaseDataRow, SupabaseTable, ClientsRow, ClientsTable, createdAt, createRow, DepartmentsRow, DepartmentsTable (+7 more)

### Community 51 - "orgs.dart"
Cohesion: 0.13
Nodes (15): avatar, cnpj, cpf, createdAt, createRow, id, name, OrgsRow (+7 more)

### Community 52 - "redefinir_senha_widget.dart"
Cohesion: 0.14
Nodes (15): RedefinirSenhaModel, build, createState, dispose, initState, legacyRoutePath, _model, RedefinirSenhaWidget (+7 more)

### Community 53 - "FlutterWindow"
Cohesion: 0.13
Nodes (13): unique_ptr, DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+5 more)

### Community 54 - "conf_email_widget.dart"
Cohesion: 0.15
Nodes (14): conf_email_model.dart, ConfEmailModel, ConfEmailWidget, _ConfEmailWidgetState, createState, dispose, _goToConfirmOtp, initState (+6 more)

### Community 55 - "recover_password_model.dart"
Cohesion: 0.13
Nodes (14): confirmPasswordFocusNode, confirmPasswordTextController, _confirmPasswordTextControllerValidator, confirmPasswordVisibility, dispose, formKey, initState, passwordFocusNode (+6 more)

### Community 56 - "win32_window.cpp"
Cohesion: 0.22
Nodes (11): wchar_t, Scale(), CreateAndShow, Destroy, Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, GetWindowClass (+3 more)

### Community 57 - "login_widget.dart"
Cohesion: 0.16
Nodes (13): /backend/schema/structs/index.dart, LoginModel, createState, dispose, initState, LoginWidget, _LoginWidgetState, _model (+5 more)

### Community 58 - "confirma_logout_widget.dart"
Cohesion: 0.16
Nodes (13): confirma_logout_model.dart, ConfirmaLogoutModel, build, ConfirmaLogoutWidget, _ConfirmaLogoutWidgetState, createState, dispose, initState (+5 more)

### Community 59 - "dart:io"
Cohesion: 0.15
Nodes (12): dart:io, bytes, csvContent, directory, file, filePath, generateCSV, writeAsBytes (+4 more)

### Community 60 - "uploaded_file.dart"
Cohesion: 0.14
Nodes (13): double?, blurHash, bytes, deserialize, FFUploadedFile, hashCode, height, name (+5 more)

### Community 61 - "option_struct.dart"
Cohesion: 0.14
Nodes (13): createOptionStruct, fromMap, fromSerializableMap, hashCode, hasId, hasName, _id, maybeFromMap (+5 more)

### Community 62 - "user_data_struct.dart"
Cohesion: 0.14
Nodes (13): createUserDataStruct, fromMap, fromSerializableMap, hashCode, hasUser, maybeFromMap, operator, toMap (+5 more)

### Community 63 - "clients.dart"
Cohesion: 0.14
Nodes (13): avatar, cnae, cnpj, createdAt, createRow, email, id, name (+5 more)

### Community 64 - "generate_p_d_f.dart"
Cohesion: 0.14
Nodes (13): customPageFormat, dateFormatter, formatDate, formatHoursToHhMm, generatePDF, parsedActivities, pdf, resolvedUserName (+5 more)

### Community 65 - "custom_functions.dart"
Cohesion: 0.14
Nodes (13): formatDropdown, formatHours, formattedDate, getLabel, getNextDay, getPreviusDate, minutes, nowUtc (+5 more)

### Community 66 - "logout_confirmado_widget.dart"
Cohesion: 0.16
Nodes (13): LogoutConfirmadoModel, createState, dispose, initState, LogoutConfirmadoWidget, _LogoutConfirmadoWidgetState, _model, routeName (+5 more)

### Community 67 - "sqlite_manager.dart"
Cohesion: 0.15
Nodes (12): /backend/sqlite/init.dart, Database get, _database, initialize, _instance, SQLiteManager, package:sqflite/sqflite.dart, queries/read.dart (+4 more)

### Community 68 - "DateTime?"
Cohesion: 0.17
Nodes (12): DateTime?, clientId, createdAt, createRow, id, ProjectClientsRow, ProjectClientsTable, projectId (+4 more)

### Community 69 - "entrar_con_senha_widget.dart"
Cohesion: 0.18
Nodes (12): entrar_con_senha_model.dart, EntrarConSenhaModel, createState, dispose, EntrarConSenhaWidget, _EntrarConSenhaWidgetState, initState, _model (+4 more)

### Community 70 - "final_registration_widget.dart"
Cohesion: 0.18
Nodes (12): final_registration_model.dart, /flutter_flow/flutter_flow_widgets.dart, FinalRegistrationModel, createState, dispose, FinalRegistrationWidget, _FinalRegistrationWidgetState, initState (+4 more)

### Community 71 - "senha_alterada_widget.dart"
Cohesion: 0.18
Nodes (12): SenhaAlteradaModel, createState, dispose, initState, _model, routeName, routePath, scaffoldKey (+4 more)

### Community 72 - "Win32Window"
Cohesion: 0.22
Nodes (13): RECT, OnCreate, OnDestroy, HWND, Win32Window, child_content_, GetClientArea, OnCreate (+5 more)

### Community 73 - "entrar_con_senha_model.dart"
Cohesion: 0.17
Nodes (11): ApiCallResponse?, entrar_con_senha_widget.dart, dispose, emailFocusNode, emailTextController, initState, loginResult, senhaFocusNode (+3 more)

### Community 74 - "structs/index.dart"
Cohesion: 0.17
Nodes (11): ativities_struct.dart, /backend/schema/util/schema_util.dart, data_saved_struct.dart, option_struct.dart, project_option_struct.dart, task_done_struct.dart, task_option_struct.dart, tasks_struct.dart (+3 more)

### Community 75 - "time_entries.dart"
Cohesion: 0.18
Nodes (11): dynamic get, createdAt, createRow, description, id, table, tableName, tasks (+3 more)

### Community 76 - "redefinir_senha_model.dart"
Cohesion: 0.17
Nodes (11): FocusNode?, FormState, FFTextEditingControllerExt, dispose, emailFocusNode, emailTextController, _emailTextControllerValidator, formKey (+3 more)

### Community 77 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 78 - "heartbeats.dart"
Cohesion: 0.18
Nodes (11): createdAt, createRow, HeartbeatsRow, HeartbeatsTable, id, lastSeen, status, table (+3 more)

### Community 79 - "tasks.dart"
Cohesion: 0.18
Nodes (11): createdAt, createRow, department, id, name, projectId, table, tableName (+3 more)

### Community 80 - "login_model.dart"
Cohesion: 0.17
Nodes (11): dispose, emailFocusNode, emailTextController, _emailTextControllerValidator, emailVerify, formKey, initState, isRemoteValue (+3 more)

### Community 81 - "package:google_fonts/google_fonts.dart"
Cohesion: 0.20
Nodes (11): NotAtivitiesModel, build, createState, dispose, initState, _model, NotAtivitiesWidget, _NotAtivitiesWidgetState (+3 more)

### Community 82 - "verify_token_model.dart"
Cohesion: 0.17
Nodes (11): clearOtp, dispose, focusFirst, initState, otp, otpControllers, otpFocusNodes, otpLength (+3 more)

### Community 83 - "auth_session.dart"
Cohesion: 0.18
Nodes (10): /auth/custom_auth/auth_util.dart, /backend/api_requests/api_config.dart, AuthSession, getValidAccessToken, handleUnauthorized, logout, _performRefresh, refreshAccessToken (+2 more)

### Community 84 - "bool get"
Cohesion: 0.18
Nodes (10): bool get, Exception, ApiClientException, body, isUnauthorized, isValidation, message, statusCode (+2 more)

### Community 85 - "NotificationService"
Cohesion: 0.22
Nodes (8): FirebaseMessaging, NotificationService, UNMutableNotificationContent, UNNotificationContent, UNNotificationRequest, UNNotificationServiceExtension, UserNotifications, Void

### Community 86 - "BaseStruct"
Cohesion: 0.18
Nodes (11): AtivitiesStruct, DataSavedStruct, OptionStruct, ProjectOptionStruct, TaskDoneStruct, TaskOptionStruct, TasksStruct, UserDataStruct (+3 more)

### Community 87 - "heartbeat_logs.dart"
Cohesion: 0.20
Nodes (10): createdAt, createRow, eventType, HeartbeatLogsRow, HeartbeatLogsTable, id, metadata, table (+2 more)

### Community 88 - "team_users.dart"
Cohesion: 0.20
Nodes (10): createdAt, createRow, id, roleInTeam, table, tableName, teamId, TeamUsersRow (+2 more)

### Community 89 - "teams.dart"
Cohesion: 0.20
Nodes (10): createdAt, createRow, description, id, name, orgId, table, tableName (+2 more)

### Community 90 - "user_projects.dart"
Cohesion: 0.20
Nodes (10): assignedAt, createRow, id, projectId, role, table, tableName, userId (+2 more)

### Community 91 - "package:flutter/foundation.dart"
Cohesion: 0.20
Nodes (8): app_updater.dart, getBaseApiUrl, accepted, checkAndPromptDesktopUpdate, silentIfNone, update, package:flutter/foundation.dart, required BuildContext context,
  bool

### Community 92 - "../database.dart"
Cohesion: 0.22
Nodes (9): ../database.dart, createdAt, createRow, roleId, table, tableName, userId, UserRolesRow (+1 more)

### Community 93 - "init.dart"
Cohesion: 0.20
Nodes (9): database, databasePath, databasesPath, exists, initializeDatabaseFromDbFile, path, package:flutter/services.dart, package:path/path.dart (+1 more)

### Community 94 - "project_teams.dart"
Cohesion: 0.22
Nodes (9): createdAt, createRow, id, projectId, ProjectTeamsRow, ProjectTeamsTable, table, tableName (+1 more)

### Community 95 - "role_permissions.dart"
Cohesion: 0.22
Nodes (9): canWrite, createRow, id, permissionId, roleId, RolePermissionsRow, RolePermissionsTable, table (+1 more)

### Community 96 - "roles.dart"
Cohesion: 0.22
Nodes (9): createdAt, createRow, id, name, RolesRow, RolesTable, table, tableName (+1 more)

### Community 97 - "user_clients.dart"
Cohesion: 0.22
Nodes (9): assignedAt, clientId, createRow, role, table, tableName, UserClientsRow, UserClientsTable (+1 more)

### Community 98 - "user_tasks.dart"
Cohesion: 0.22
Nodes (9): assignedAt, createRow, status, table, tableName, taskId, userId, UserTasksRow (+1 more)

### Community 99 - "instant_timer.dart"
Cohesion: 0.24
Nodes (9): cancel, InstantTimer, isActive, periodic, _startImmediately, tick, _timer, TimerExt (+1 more)

### Community 100 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.20
Nodes (7): package:flutter_test/flutter_test.dart, package:zoc/backend/api_requests/api_calls.dart, package:zoc/desktop/app_updater.dart, package:zoc/main.dart, main, main, main

### Community 101 - "MessageHandler"
Cohesion: 0.36
Nodes (10): HWND, LPARAM, LRESULT, UINT, WPARAM, EnableFullDpiSupportIfAvailable(), GetHandle, GetThisFromHandle (+2 more)

### Community 102 - "custom_auth_user_provider.dart"
Cohesion: 0.22
Nodes (8): BehaviorSubject, custom_auth_manager.dart, loggedIn, uid, Zoc1AuthUser, zoc1AuthUserStream, zoc1AuthUserSubject, package:rxdart/rxdart.dart

### Community 103 - "dart:convert"
Cohesion: 0.22
Nodes (7): dart:convert, getStreamedResponse, package:http/http.dart, package:http/testing.dart, package:zoc/auth/custom_auth/custom_auth_manager.dart, package:zoc/auth/custom_auth/custom_auth_user_provider.dart, main

### Community 104 - "compress_screenshot.dart"
Cohesion: 0.22
Nodes (8): dart:typed_data, base64Encode, compressScreenshotBase64, decoded, maxWidth, quality, resized, package:image/image.dart

### Community 105 - "DateTime get"
Cohesion: 0.25
Nodes (7): CustomAuthManager get, DateTime get, _authManager, currentAuthenticationToken, currentAuthRefreshToken, currentAuthTokenExpiration, currentUserUid

### Community 106 - "capture_screenshot_web.dart"
Cohesion: 0.25
Nodes (7): dart:async, dart:js_interop, captureScreenshotBase64, completer, _stopStream, _waitForVideoFrame, package:web/web.dart

### Community 107 - "FFLocalizations"
Cohesion: 0.33
Nodes (7): CupertinoLocalizations, FallbackCupertinoLocalizationDelegate, FallbackMaterialLocalizationDelegate, FFLocalizations, FFLocalizationsDelegate, LocalizationsDelegate, MaterialLocalizations

### Community 108 - "schema_util.dart"
Cohesion: 0.29
Nodes (6): getColorsList, getSchemaColor, serialize, toSerializableMap, package:collection/collection.dart, package:from_css_color/from_css_color.dart

### Community 109 - "handle_new_rx_page"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 110 - "Map"
Cohesion: 0.33
Nodes (5): data, SqliteRow, MapFilterExtensions, NavParamExtensions, Map

### Community 111 - "actions/index.dart"
Cohesion: 0.40
Nodes (4): check_if_email_exists.dart, generate_c_s_v.dart, generate_p_d_f.dart, send_verification_email.dart

### Community 112 - "Iterable"
Cohesion: 0.40
Nodes (5): Iterable, IterableExt, ListDivideExt, ListFilterExt, ListUniqueExt

### Community 113 - "/backend/api_requests/api_calls.dart"
Cohesion: 0.50
Nodes (3): /backend/api_requests/api_calls.dart, response, sendVerificationEmail

### Community 114 - "api_requests/api_manager.dart"
Cohesion: 0.50
Nodes (3): configureAuthSession, _executeRequest, syncAccessToken

### Community 116 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 117 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 119 - "GoRouter"
Cohesion: 0.67
Nodes (3): GoRouter, GoRouterExtensions, GoRouterLocationExtension

### Community 120 - "TextStyle"
Cohesion: 0.67
Nodes (3): TextStyleHelper, _WithoutColorExtension, TextStyle

## Knowledge Gaps
- **1702 isolated node(s):** `PackageDescription`, `FirebaseMessaging`, `UserNotifications`, `UIKit`, `Flutter` (+1697 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1997 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **63 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `T` connect `ativities_struct.dart` to `flutter_flow_util.dart`, `nav.dart`, `flutter_flow_data_table.dart`, `flutter_flow_drop_down.dart`, `serialization_util.dart`, `schema_util.dart`, `String get`, `flutter_flow_model.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Why does `FFAppState` connect `FFAppState` to `app_state.dart`, `logout_widget.dart`, `info_widget.dart`, `entrar_con_senha_widget.dart`, `popup_dialog_widget.dart`, `expediente_widget.dart`, `email_enviado_widget.dart`, `conf_email_widget.dart`, `login_widget.dart`, `AppStateNotifier`, `verify_token_widget.dart`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Why does `Zoc1AuthUser` connect `custom_auth_user_provider.dart` to `custom_auth_manager.dart`, `nav.dart`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **What connects `PackageDescription`, `FirebaseMessaging`, `UserNotifications` to the rest of the system?**
  _1702 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02197802197802198 - nodes in this community are weakly interconnected._
- **Should `flutter_flow_util.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022727272727272728 - nodes in this community are weakly interconnected._
- **Should `flutter_flow_theme.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.023529411764705882 - nodes in this community are weakly interconnected._