// Conditional export: web gets a no-op stub, mobile/desktop get the real service.
export 'notification_service_mobile.dart'
    if (dart.library.html) 'notification_service_web.dart';
