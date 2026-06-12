import '../models/vision_result.dart';
import '../network/api_client.dart';
import '../network/default_api_client.dart';
import '../utils/logger.dart';

/// Repository for Smart Scan vision API calls (ADR-0005)
///
/// Backend is the single source of truth for scan history; user corrections
/// sent here become training data for the hybrid phase.
class VisionRepository {
  static const String _tag = 'VisionRepository';

  final ApiClient _apiService;

  VisionRepository({ApiClient? apiClient})
      : _apiService = apiClient ?? defaultApiClient;

  /// Upload an image and get a volume estimate.
  /// The backend persists the scan (with image) and returns its scan_id.
  Future<VisionResult> estimateVolume(String imagePath) async {
    AppLogger.info(_tag, 'Estimating volume from image: $imagePath');

    try {
      final response = await _apiService.upload<VisionResult>(
        '/vision/estimate-volume',
        filePath: imagePath,
        fieldName: 'image',
        fromJson: (json) => VisionResult.fromJson(json as Map<String, dynamic>),
      );

      if (response.data == null) {
        throw Exception('Vision estimate response data is null');
      }

      AppLogger.info(_tag, 'Vision result: ${response.data}');
      return response.data!;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to estimate volume', e);
      rethrow;
    }
  }

  /// Record the user's decision on a scan. Confirming as-is validates the
  /// AI estimate; passing [correctedVolumeMl] records a correction.
  Future<void> submitValidation({
    required String scanId,
    int? correctedVolumeMl,
  }) async {
    AppLogger.info(
      _tag,
      'Submitting scan validation: $scanId '
      '(corrected: ${correctedVolumeMl ?? "no"})',
    );

    try {
      await _apiService.put<dynamic>(
        '/vision/scan-history/$scanId',
        data: {
          'is_validated': true,
          if (correctedVolumeMl != null)
            'user_corrected_volume_ml': correctedVolumeMl,
        },
        fromJson: (json) => json,
      );
    } catch (e) {
      // Validation is telemetry/training data — never block the log flow on it
      AppLogger.error(_tag, 'Failed to submit scan validation: $scanId', e);
    }
  }
}
