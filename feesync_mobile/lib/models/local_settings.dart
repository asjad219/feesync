class LocalSettings {
  final bool biometricEnabled;
  final bool pinLockEnabled;
  final bool sessionAlertsEnabled;
  final double aiConfidenceThreshold;
  final String? pinHash; // SHA-256 hash of the PIN, stored in secure storage separately

  LocalSettings({
    required this.biometricEnabled,
    required this.pinLockEnabled,
    required this.sessionAlertsEnabled,
    required this.aiConfidenceThreshold,
    this.pinHash,
  });

  factory LocalSettings.defaultSettings() {
    return LocalSettings(
      biometricEnabled: false,
      pinLockEnabled: false,
      sessionAlertsEnabled: true,
      aiConfidenceThreshold: 0.8,
      pinHash: null,
    );
  }

  factory LocalSettings.fromJson(Map<String, dynamic> json) {
    return LocalSettings(
      biometricEnabled: json['biometric_enabled'] ?? false,
      pinLockEnabled: json['pin_lock_enabled'] ?? false,
      sessionAlertsEnabled: json['session_alerts_enabled'] ?? true,
      aiConfidenceThreshold: (json['ai_confidence_threshold'] ?? 0.8) as double,
      pinHash: json['pin_hash'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biometric_enabled': biometricEnabled,
      'pin_lock_enabled': pinLockEnabled,
      'session_alerts_enabled': sessionAlertsEnabled,
      'ai_confidence_threshold': aiConfidenceThreshold,
      'pin_hash': pinHash,
    };
  }

  LocalSettings copyWith({
    bool? biometricEnabled,
    bool? pinLockEnabled,
    bool? sessionAlertsEnabled,
    double? aiConfidenceThreshold,
    String? pinHash,
    bool clearPin = false,
  }) {
    return LocalSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
      sessionAlertsEnabled: sessionAlertsEnabled ?? this.sessionAlertsEnabled,
      aiConfidenceThreshold: aiConfidenceThreshold ?? this.aiConfidenceThreshold,
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
    );
  }
}
