/// Auth feature exports
///
/// Provides convenient access to auth-related classes và providers.
/// This barrel file makes importing auth functionality easier.

// Domain entities
export 'domain/entities/user.dart';
export 'domain/auth_service.dart';

// Data models
export 'data/models/auth_models.dart';

// Presentation providers
export 'presentation/providers/auth_providers.dart';

// Common auth types
export 'domain/auth_service.dart' show AuthResult;