class LocalSettings {
  final bool biometricEnabled;
  final bool pinLockEnabled;
  final bool sessionAlertsEnabled;
  final double aiConfidenceThreshold;

  LocalSettings({
    required this.biometricEnabled,
    required this.pinLockEnabled,
    required this.sessionAlertsEnabled,
    required this.aiConfidenceThreshold,
  });

  factory LocalSettings.defaultSettings() {
    return LocalSettings(
      biometricEnabled: true,
      pinLockEnabled: false,
      sessionAlertsEnabled: true,
      aiConfidenceThreshold: 0.8,
    );
  }

  factory LocalSettings.fromJson(Map<String, dynamic> json) {
    return LocalSettings(
      biometricEnabled: json['biometric_enabled'] ?? true,
      pinLockEnabled: json['pin_lock_enabled'] ?? false,
      sessionAlertsEnabled: json['session_alerts_enabled'] ?? true,
      aiConfidenceThreshold: (json['ai_confidence_threshold'] ?? 0.8) as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'biometric_enabled': biometricEnabled,
      'pin_lock_enabled': pinLockEnabled,
      'session_alerts_enabled': sessionAlertsEnabled,
      'ai_confidence_threshold': aiConfidenceThreshold,
    };
  }

  LocalSettings copyWith({
    bool? biometricEnabled,
    bool? pinLockEnabled,
    bool? sessionAlertsEnabled,
    double? aiConfidenceThreshold,
  }) {
    return LocalSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
      sessionAlertsEnabled: sessionAlertsEnabled ?? this.sessionAlertsEnabled,
      aiConfidenceThreshold: aiConfidenceThreshold ?? this.aiConfidenceThreshold,
    );
  }
}
