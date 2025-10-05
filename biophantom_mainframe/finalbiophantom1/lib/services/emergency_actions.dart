class EmergencyActionsService {
  // Suggest instant actions based on risk
  String getAction(double riskScore) {
    if (riskScore > 0.9) {
      return 'Sit down, hydrate, move to fresh air, and call a doctor.';
    } else if (riskScore > 0.7) {
      return 'Monitor symptoms, avoid strenuous activity, and stay safe.';
    }
    return 'No emergency action needed.';
  }
}
