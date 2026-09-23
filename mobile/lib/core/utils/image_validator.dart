class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ImageValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const ImageValidationResult.invalid(this.errorMessage) : isValid = false;
}

class ImageValidator {
  static const int maxSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedExtensions = ['.png', '.jpg', '.jpeg'];

  /// Validates that an image file has a PNG or JPEG extension and is less than 5 MB.
  static ImageValidationResult validateImage({
    required String fileName,
    required int byteLength,
  }) {
    final lowerName = fileName.trim().toLowerCase();
    final hasValidExt = allowedExtensions.any((ext) => lowerName.endsWith(ext));
    if (!hasValidExt) {
      return const ImageValidationResult.invalid(
        'Images should be in PNG or JPEG format.',
      );
    }

    if (byteLength >= maxSizeBytes) {
      return const ImageValidationResult.invalid(
        'Images should be less than 5 MB.',
      );
    }

    return const ImageValidationResult.valid();
  }
}
